# Implement

Set up a worktree and execute the implementation plan from a documentation file
**interactively**. The full step list is displayed grouped upfront, and you verify the diff
before each commit.

This command runs the shared implementation loop in **`interactive`** mode — see
**`~/.claude/workflow/_interactive-loop.md`**. Shared behavior (branch naming, the context-file
schema, commit conventions) lives in the `~/.claude/workflow/` modules referenced below.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

Required: a **path to a documentation file** created by `/plan`:

```
/implement <path/to/doc.md>
```

If no arguments are provided, stop and tell the user to provide a doc file path. Suggest running
`/plan` first if they don't have one.

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

Verify the doc has an `### Implementation Steps` or `### Approach` section. If not, stop and tell
the user the doc needs an implementation plan. Suggest they run `/plan {doc-path}` to add one.

#### Determine the branch name

Resolve the branch name and **branch slug** by following
**`~/.claude/workflow/_branch-naming.md`** (doc **Branch** field if present, otherwise
`{type}/{branch-slug}` derived from the doc type and filename). The branch slug is reused for the
worktree directory and the context filename below.

### 2. Pre-flight check

- Confirm we are on `main` (or the repo's default branch). If not and there are no uncommitted
  changes, automatically switch to `main`. If there are uncommitted changes, stop and tell the
  user to commit or stash first.
- Run `git pull` to ensure `main` is up to date.

### 3. Create the worktree

```bash
mkdir -p .claude/worktrees
git worktree add .claude/worktrees/{branch-slug} -b {branch-name}
```

### 4. Create the context file

Create `.context.{branch-slug}.md` in the worktree root using the **base section** schema in
**`~/.claude/workflow/_state-file.md`** (Context heading; Type, Branch, Merge Into, Doc directory,
Created date; Description; Documentation → Doc path). This file is the state contract consumed by
`/implement-pause`, `/implement-continue`, `/stage`, and `/release`.

### 5. Copy config + install deps + baseline build

From the main conversation, in the worktree:

- Copy (only if present): `CLAUDE.md`, `.claude/` directory, `.mcp.json`, all root `.env*` files,
  and all `supabase/.env*` files (preserving the `supabase/` subdirectory path in the worktree).
- Detect package manager from lockfile and install: `bun.lockb` → `bun install`,
  `pnpm-lock.yaml` → `pnpm install`, `yarn.lock` → `yarn install`,
  `package-lock.json`/`package.json` → `npm install`. Otherwise skip.
- Run the `build` script to verify a clean baseline. If it fails, stop — do not attempt
  implementation on a broken base.

**Always** use `git -C {worktree}` / `--prefix {worktree}` / absolute paths. Never chain commands
with `&&`, `||`, or `;` (see `~/.claude/workflow/_commit-conventions.md`).

---

## Phase 2: Run the implementation loop

Set **`$MODE = interactive`** and run the shared loop in
**`~/.claude/workflow/_interactive-loop.md`**:

1. **Group the steps** and **print the grouped plan** (total steps, group names, per-step
   summaries, branch, worktree path), then tell the user: "I'll implement each step, show you the
   diff, and wait for your OK before committing."
2. **Per-step procedure** — announce → implement → show diff → **AskUserQuestion** checkpoint
   (`Commit & continue` / `Revise` / `Skip commit` / `Abort`) → commit on approval. On `Abort`,
   print the resume command `/implement-continue {branch-slug}`. Error recovery: up to 3 fixes,
   then `Retry` / `Skip step` / `Abort`.
3. **Final verification** — update the doc status and acceptance criteria; run `build` (required),
   `lint`, and `test`; then present the final report.

Commits follow **`~/.claude/workflow/_commit-conventions.md`** (`type(scope): description`, stage
only the step's files, no co-author trailer).

### Final report contents

- Worktree path and branch name, plus `cd .claude/worktrees/{branch-slug}`
- Summary of what was implemented (grouped, matching the printed plan)
- Commit count
- Acceptance criteria: passed / outstanding
- Build / lint / test status
- Next: `/stage` when ready
- Cleanup: `git worktree remove .claude/worktrees/{branch-slug}`

---

## Phase 3: Compact the conversation

After presenting the final report, invoke the `/compact` command to compress the conversation
context. This conserves daily rate limit usage.
