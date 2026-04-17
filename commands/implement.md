# Implement

Set up a worktree and execute the implementation plan from a documentation file **interactively**. The full step list is displayed grouped upfront, and you verify the diff before each commit.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

Required: a **path to a documentation file** created by `/plan`:

```
/implement <path/to/doc.md>
```

If no arguments are provided, stop and tell the user to provide a doc file path. Suggest running `/plan` first if they don't have one.

---

## Phase 1: Setup (main conversation)

Lightweight orchestration — parse just enough to create the worktree.

### 1. Parse the doc file

Read the `.md` file and extract:

- **Title** — from the `#` heading
- **Type** — from the `**Type:**` field (e.g., `Feature`, `Enhancement`, `Bug`)
- **Description** — from the `## Summary` section
- **Doc path** — the absolute path to the doc file
- **Doc directory** — the directory the doc file lives in
- **Branch** — from the `**Branch:**` field (if present)
- **Merge Into** — from the `**Merge Into:**` field (defaults to `main` if not present)
- **Implementation Steps** — from `### Implementation Steps` or `### Approach`
- **Acceptance Criteria** — from `## Acceptance Criteria`
- **Key Files** — from `### Key Files` (if present)

Verify the doc has an `### Implementation Steps` or `### Approach` section. If not, stop and tell the user the doc needs an implementation plan. Suggest they run `/plan {doc-path}` to add one.

#### Determine the branch name

If the doc has a **Branch** field with a non-empty value → use it directly as the branch name.

Otherwise, derive the branch name from the doc type and filename:

1. Generate the **branch slug** from the doc filename (strip `.md`, e.g., `admin-profile-linking.md` → `admin-profile-linking`).
2. Use the doc type (lowercased) as the branch prefix (`feature` → `feature/`, `bug` → `bug/`, `refactor` → `refactor/`, `hotfix` → `hotfix/`). If type is missing, default to `feature/`.
3. Combine: `{type}/{branch-slug}`.

### 2. Pre-flight check

- Confirm we are on `main` (or the repo's default branch). If not and there are no uncommitted changes, automatically switch to `main`. If there are uncommitted changes, stop and tell the user to commit or stash first.
- Run `git pull` to ensure `main` is up to date.

### 3. Create the worktree

```bash
mkdir -p .claude/worktrees
git worktree add .claude/worktrees/{branch-slug} -b {branch-name}
```

### 4. Create the context file

Create `.context.{branch-slug}.md` in the worktree root:

```markdown
# Context: {Doc Title}

- **Type**: {type}
- **Branch**: {branch-name}
- **Merge Into**: {merge-into}
- **Doc directory**: {doc directory}
- **Created**: {current date YYYY-MM-DD}

## Description

{Summary from the doc file}

## Documentation

- **Doc path**: {absolute path to the doc file}
```

### 5. Copy config + install deps + baseline build

From the main conversation, in the worktree:

- Copy (only if present): `CLAUDE.md`, `.claude/` directory, `.mcp.json`, all `.env*` files.
- Detect package manager from lockfile and install: `bun.lockb` → `bun install`, `pnpm-lock.yaml` → `pnpm install`, `yarn.lock` → `yarn install`, `package-lock.json`/`package.json` → `npm install`. Otherwise skip.
- Run the `build` script to verify a clean baseline. If it fails, stop — do not attempt implementation on a broken base.

**Always** use `git -C {worktree}` / `--prefix {worktree}` / absolute paths. Never chain commands with `&&`, `||`, or `;`.

---

## Phase 2: Display grouped plan

Before touching any code, print a grouped overview of the work so the user sees the full scope.

### 6. Group the implementation steps

Group steps by natural clusters from the doc:
- If the doc uses `####` subsections or phase headings → use those as groups.
- If steps reference distinct files/modules → group by file/module.
- If steps are flat and unrelated → treat each step as its own single-step group.

### 7. Print the plan to the terminal

Display in this format (plain markdown, rendered directly in chat):

```
## Implementation plan: {Doc Title}

Branch: {branch-name}
Worktree: .claude/worktrees/{branch-slug}
Total steps: {N} across {G} groups

### Group 1: {group name}
1. {step 1 summary}
2. {step 2 summary}

### Group 2: {group name}
3. {step 3 summary}
...
```

Then tell the user: "I'll implement each step, show you the diff, and wait for your OK before committing."

---

## Phase 3: Interactive step-by-step implementation

For each step, in order:

### 8. Announce the step

One line before starting: `→ Step {n}/{N} ({group name}): {step summary}`.

### 9. Implement the step

- Read relevant files in the worktree (absolute paths).
- Follow existing patterns — check the worktree's `CLAUDE.md` if present.
- Make the code changes with Edit/Write.
- Do NOT stage or commit yet.

### 10. Show the diff

Run `git -C {worktree} status` and `git -C {worktree} diff` (and `git -C {worktree} diff --stat` for context). Display the output to the user. Summarize in 1-3 sentences what changed and why.

### 11. Ask the user to verify

Use **AskUserQuestion** with:

- Question: `Step {n}/{N} — {step summary}. Commit these changes and continue?`
- Options:
  - `Commit & continue` — stage changes, commit with conventional commit format, proceed to next step.
  - `Revise` — user will describe changes; do not commit. Apply the revision, re-show diff, re-ask.
  - `Skip commit` — leave changes uncommitted, move to next step anyway (rare; warn that state will carry into the next step's diff).
  - `Abort` — stop the whole `/implement` run. Print instructions for resuming via `/implement-continue {branch-slug}`.

### 12. On `Commit & continue`

- Stage only the files changed in this step (`git -C {worktree} add {files}`).
- Commit with `type(scope): description` format.
  - Single-line: `git -C {worktree} commit -m "..."`.
  - Multi-line: write to `/tmp/commit-msg.txt`, then `git -C {worktree} commit -F /tmp/commit-msg.txt`. Never use HEREDOC or `$()`.
- Proceed to the next step.

### 13. Error recovery during a step

If implementation fails (syntax error, test fails, etc.):
- Attempt up to 3 fixes.
- If still broken, surface the error to the user via AskUserQuestion with options: `Retry`, `Skip step`, `Abort`.
- Do NOT loop indefinitely.

---

## Phase 4: Final verification

### 14. Update documentation

- If ALL acceptance criteria are met → set `**Status:**` to `Done`.
- If SOME are met → set `**Status:**` to `In Progress`.
- Check off completed `- [ ]` criteria.
- Show diff, ask user to confirm (same verification pattern as Phase 3), then commit: `docs: update status and acceptance criteria`.

### 15. Build / lint / test

Run from `package.json` scripts using the detected package manager:
- `build` (required)
- `lint` (if script exists)
- `test` (if script exists)

Show results to the user. If any fail, attempt fixes (up to 3 total) with the same verification pattern before committing.

### 16. Present final report

Print:
- Worktree path and branch name
- `cd .claude/worktrees/{branch-slug}`
- Summary of what was implemented (grouped, matching Phase 2)
- Commit count
- Acceptance criteria: passed / outstanding
- Build / lint / test status
- Next: `/stage` when ready
- Cleanup: `git worktree remove .claude/worktrees/{branch-slug}`
