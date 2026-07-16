# Implement Pause

Pause an in-progress implementation: commit all uncommitted changes, ensure the implementation doc has a remote branch recorded, and push the branch to remote so it can be resumed on any machine.

## Input

No arguments. Context is detected automatically from the current worktree.

---

## Steps

### 1. Detect current implementation

Locate the active implementation context (`.context.*.md` schema:
`~/.claude/workflow/_state-file.md`):
- If inside a worktree, find `.context.*.md` in the worktree root.
- Otherwise, search `.claude/worktrees/*/` for `.context.*.md` files. If exactly one is found, use it. If multiple are found, list them and ask the user to pick one via **AskUserQuestion**.
- If none is found, stop and tell the user: no active implementation was detected.

From the context file, extract:
- `slug` — derived from the context filename (`.context.{slug}.md`)
- `branch` — from the `**Branch:**` field
- `doc-path` — from the `**Doc path:**` field
- `worktree` — `.claude/worktrees/{slug}`

### 2. Commit all uncommitted changes

Run `git -C {worktree} status` to check for staged or unstaged changes.

If there are uncommitted changes, invoke `/commit` to commit them. Wait for the commit to complete before continuing.

If the worktree is clean, skip this step.

### 3. Ensure the doc has a Branch field

Read the doc file at `{doc-path}`. Look for a `**Branch:**` field in the document metadata (typically near the top, alongside `**Type:**`, `**Status:**`, etc.).

- **Field exists and is non-empty** → no change needed; use its value as the remote branch name.
- **Field is missing or empty** → determine the branch name from `git -C {worktree} branch --show-current`, then add or update the field:

  ```markdown
  **Branch:** {branch-name}
  ```

  Place it alongside the other metadata fields (after `**Type:**` if present, otherwise after the first `**...**` metadata line).

  After editing the doc, commit the change from the **main repo** (not the worktree), since the doc file lives outside the worktree (commit rules: `~/.claude/workflow/_commit-conventions.md`):

  ```
  git add {doc-path}
  git commit -m "docs({slug}): add Branch metadata for remote resume"
  ```

### 4. Push to remote

From within the worktree, get the current branch: `git -C {worktree} branch --show-current`.

Attempt to push:

```bash
git -C {worktree} push
```

If the push fails because no upstream is set (exit code non-zero, message references `--set-upstream` or `no upstream`), create the remote branch:

```bash
git -C {worktree} push --set-upstream origin {branch-name}
```

If the push fails for any other reason (auth, network, conflict), show the error and stop — do not silently swallow it.

### 5. Report

Tell the user:
- Branch pushed to: `origin/{branch-name}`
- Worktree path: `.claude/worktrees/{slug}`
- Commits on branch: output of `git -C {worktree} log --oneline {merge-into}..HEAD`
- How to resume on any machine: `/implement-continue {slug}`

### 6. Compact the conversation

After reporting, invoke the `/compact` command to compress the conversation context. This conserves daily rate limit usage.
