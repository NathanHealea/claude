# Implement Continue

Fetch an implementation branch from remote source control, set up its worktree on this machine (if not already present), and resume interactive step-by-step implementation.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

- **slug** (required) — the document name of the implementation (e.g., `hue-value-suggestions`). Strip `.md` if accidentally included.
- **branch** (optional) — the remote branch the worktree code was pushed to (e.g., `feature/hue-value-suggestions`).

If no arguments are provided, stop and tell the user: `Usage: /implement-continue <slug> [branch]`.

---

## Phase 1: Determine Branch

### 1. Parse arguments

Extract:
- `slug` — first argument (required).
- `branch` — second argument (optional). If provided, skip steps 2–3 and go directly to Phase 2.

### 2. Locate the doc file and read metadata (if no branch provided)

Search for a file named `{slug}.md` in these locations, in order:
1. `.claude/docs/{slug}.md`
2. `docs/{slug}.md`
3. `./{slug}.md`
4. Any `*.md` file in the project whose filename (without extension) matches the slug exactly.

If a doc file is found, read it and look for a `**Branch:**` field. If the field is present and non-empty, use that value as `branch` and skip to Phase 2.

### 3. Infer branch from remote refs (if not found in doc)

If no branch was determined from the doc metadata:

1. Run `git fetch --all` to sync remote refs.
2. Search remote branches for the slug: `git branch -r | grep {slug}`
3. If **exactly one** match is found, propose it to the user via **AskUserQuestion**:
   - Question: `Found remote branch: {branch}. Use this to set up the worktree?`
   - Options: `Yes, use this branch` / `Enter a different branch`
4. If **multiple** matches are found, list them via **AskUserQuestion** and ask the user to pick one.
5. If **no** matches are found, ask the user to supply the branch name manually via **AskUserQuestion**.

---

## Phase 2: Set Up Worktree

### 4. Check for an existing worktree

Check whether `.claude/worktrees/{slug}` already exists:

- **Exists and on the correct branch** → run `git -C .claude/worktrees/{slug} pull` to update, then skip to Phase 3.
- **Exists but on a different branch** → stop and warn the user; suggest they remove the stale worktree with `git worktree remove .claude/worktrees/{slug}` and re-run the command.
- **Does not exist** → continue to step 5.

### 5. Fetch the remote branch

```bash
git fetch origin {branch}
```

If the fetch fails (branch not found on remote), stop and tell the user — confirm the branch name and remote access.

### 6. Create the worktree

```bash
mkdir -p .claude/worktrees
git worktree add .claude/worktrees/{slug} --track -b {branch} origin/{branch}
```

If a local branch named `{branch}` already exists (previously fetched), omit `--track -b {branch}`:

```bash
git worktree add .claude/worktrees/{slug} {branch}
```

### 7. Verify the worktree

Run and display:
- `git -C .claude/worktrees/{slug} branch --show-current` — confirm correct branch.
- `git -C .claude/worktrees/{slug} log --oneline -5` — show recent commits.
- `git -C .claude/worktrees/{slug} status` — confirm clean state.

---

## Phase 3: Set Up Environment

### 8. Copy config files

Copy from the main repo root into the worktree (skip if the file/dir does not exist):
- `CLAUDE.md`
- `.claude/` directory
- `.mcp.json`
- All `.env*` files

### 9. Install dependencies

Detect package manager from lockfile and install:
- `bun.lockb` → `bun install`
- `pnpm-lock.yaml` → `pnpm install`
- `yarn.lock` → `yarn install`
- `package-lock.json` / `package.json` → `npm install`

Skip if no lockfile is found.

### 10. Run baseline build

Run the `build` script to verify the worktree compiles cleanly. If it fails, stop and tell the user — do not attempt to resume implementation on a broken base.

**Always** use `git -C {worktree}` / absolute paths. Never chain commands with `&&`, `||`, or `;`.

---

## Phase 4: Assessment

### 11. Read the context file

Look for `.context.{slug}.md` in the worktree root. If found, extract:
- Doc path, branch name, type, description, merge-into branch
- Any `## Progress` section (paused state from a previous session)

If not found, skip to step 12.

### 12. Locate the doc file

Use the doc path from the context file (if available), or use the file found in step 2, or re-search for `{slug}.md` as described in step 2.

Read the doc and extract:
- Implementation steps (`### Implementation Steps` or `### Approach`)
- Acceptance criteria (`## Acceptance Criteria`)
- Key files (`### Key Files`, if present)
- Merge Into branch (`**Merge Into:**`, defaults to `main`)

### 13. Handle uncommitted changes (if any)

If `git -C .claude/worktrees/{slug} status` shows uncommitted changes:
- Show `git -C .claude/worktrees/{slug} status` and `git -C .claude/worktrees/{slug} diff`.
- Use **AskUserQuestion**: `Uncommitted changes found. What should I do?`
  - `Commit now` — ask for a short message, commit, then proceed.
  - `Keep & integrate` — leave in place; they'll fold into the next step's diff.
  - `Discard` — only with explicit confirmation (destructive); run `git -C .claude/worktrees/{slug} restore .`.
  - `Abort` — stop.

### 14. Print resume summary

Print:
```
## Resuming: {Doc Title}

Branch:   {branch-name}
Worktree: .claude/worktrees/{slug}
cd .claude/worktrees/{slug}

Commits on branch: {count}
{short log of commits on branch vs merge-into}
```

---

## Phase 5: Determine Remaining Work

### 15. Identify what's left

Compare doc steps and acceptance criteria against:
- Commits on the branch (`git -C {worktree} log --oneline {merge-into}..HEAD`)
- Current state of the code in the worktree

Identify which steps are already complete and which remain.

### 16. Group remaining steps

Group steps by natural clusters:
- Use `####` subsections or phase headings if present in the doc.
- Group by file/module if steps reference distinct areas.
- Otherwise, treat each step as its own group.

### 17. Print the plan

```
Remaining: {R} steps across {G} groups

### Group 1: {group name}
1. {step summary}

### Group 2: {group name}
2. {step summary}
...
```

Then tell the user: "I'll implement each remaining step, show you the diff, and wait for your OK before committing."

If all steps appear complete, tell the user and jump to Phase 6.

---

## Phase 6: Interactive Step-by-Step Implementation

For each remaining step, in order:

### 18. Announce the step

One line: `→ Step {n}/{R} ({group name}): {step summary}`.

### 19. Implement the step

- Read relevant files in the worktree (absolute paths).
- Follow existing patterns — check the worktree's `CLAUDE.md` if present.
- Make the code changes with Edit/Write.
- Do NOT stage or commit yet.

**Always** use `git -C {worktree}` / absolute paths. Never chain commands with `&&`, `||`, or `;`.

### 20. Show the diff

Run `git -C {worktree} status` and `git -C {worktree} diff` (plus `git -C {worktree} diff --stat`). Display to the user. Summarize in 1–3 sentences what changed and why.

### 21. Ask the user to verify

Use **AskUserQuestion** with:

- Question: `Step {n}/{R} — {step summary}. Commit these changes and continue?`
- Options:
  - `Commit & continue` — stage changes, commit with conventional commit format, proceed.
  - `Revise` — user describes changes; do not commit. Apply revision, re-show diff, re-ask.
  - `Skip commit` — leave uncommitted, move on (warn that state carries into next step's diff).
  - `Abort` — stop. Print: `/implement-continue {slug}` to resume again later.

### 22. On `Commit & continue`

- Stage only the files changed in this step (`git -C {worktree} add {files}`).
- Commit with `type(scope): description` format.
  - Single-line: `git -C {worktree} commit -m "..."`.
  - Multi-line: write to `/tmp/commit-msg.txt`, then `git -C {worktree} commit -F /tmp/commit-msg.txt`. Never use HEREDOC or `$()`.
- Proceed to the next step.

### 23. Error recovery

If implementation fails:
- Attempt up to 3 fixes.
- If still broken, surface the error via **AskUserQuestion**: `Retry`, `Skip step`, `Abort`.
- Do NOT loop indefinitely.

---

## Phase 7: Final Verification

### 24. Update documentation

- If ALL acceptance criteria are met → set `**Status:**` to `Done`.
- If SOME are met → set `**Status:**` to `In Progress`.
- Check off newly completed `- [ ]` criteria.
- Show diff, ask user to confirm, then commit: `docs: update status and acceptance criteria`.

### 25. Build / lint / test

Run from `package.json` scripts using the detected package manager:
- `build` (required)
- `lint` (if script exists)
- `test` (if script exists)

Show results. If any fail, attempt fixes (up to 3 total) with the same verify-before-commit pattern.

### 26. Present final report

Print:
- Worktree path and branch name
- `cd .claude/worktrees/{slug}`
- Summary of what was implemented this session (grouped, matching Phase 5)
- Commits this session / total on branch
- Acceptance criteria: passed / outstanding
- Build / lint / test status
- Next: `/stage` when ready
- Cleanup: `git worktree remove .claude/worktrees/{slug}`

### 27. Compact the conversation

After presenting the final report, invoke the `/compact` command to compress the conversation context. This conserves daily rate limit usage.
