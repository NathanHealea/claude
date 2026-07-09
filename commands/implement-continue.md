# Implement Continue

Fetch an implementation branch from remote source control, set up its worktree on this machine
(if not already present), and resume interactive step-by-step implementation.

This command reuses the shared implementation loop in **`~/.claude/workflow/_interactive-loop.md`**
(run in **`interactive`** mode) and the state-file contract in
**`~/.claude/workflow/_state-file.md`**. Only the fetch/resume setup below is unique to this
command.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

- **slug** (required) — the document name of the implementation (e.g., `hue-value-suggestions`).
  Strip `.md` if accidentally included.
- **branch** (optional) — the remote branch the worktree code was pushed to (e.g.,
  `feature/hue-value-suggestions`).

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

If a doc file is found, read it and look for a `**Branch:**` field. If the field is present and
non-empty, use that value as `branch` and skip to Phase 2.

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

Look for `.context.{slug}.md` in the worktree root (schema: `~/.claude/workflow/_state-file.md`).
If found, extract:
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

Identify which steps are already complete and which remain. If all steps appear complete, tell the
user and jump straight to final verification.

---

## Phase 6: Run the implementation loop

Set **`$MODE = interactive`** and run the shared loop in
**`~/.claude/workflow/_interactive-loop.md`**, scoped to the **remaining** steps from Phase 5:

1. **Group the remaining steps** and **print the plan** (`Remaining: {R} steps across {G} groups`,
   group names, per-step summaries), then tell the user: "I'll implement each remaining step, show
   you the diff, and wait for your OK before committing."
2. **Per-step procedure** — announce (`→ Step {n}/{R} ...`) → implement → show diff →
   **AskUserQuestion** checkpoint (`Commit & continue` / `Revise` / `Skip commit` / `Abort`) →
   commit on approval. On `Abort`, print `/implement-continue {slug}` to resume later. Error
   recovery: up to 3 fixes, then `Retry` / `Skip step` / `Abort`.
3. **Final verification** — update the doc status and acceptance criteria; run `build` (required),
   `lint`, and `test`; then present the final report.

Commits follow **`~/.claude/workflow/_commit-conventions.md`**.

### Final report contents

- Worktree path and branch name, plus `cd .claude/worktrees/{slug}`
- Summary of what was implemented this session (grouped, matching Phase 5)
- Commits this session / total on branch
- Acceptance criteria: passed / outstanding
- Build / lint / test status
- Next: `/stage` when ready
- Cleanup: `git worktree remove .claude/worktrees/{slug}`

---

## Phase 7: Compact the conversation

After presenting the final report, invoke the `/compact` command to compress the conversation
context. This conserves daily rate limit usage.
