# Implement Pause

Pause an in-progress implementation, saving state so it can be resumed later.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

Optional: a **branch slug** (e.g., `hue-value-suggestions`). If omitted, detect from the current worktree.

---

## Steps

### 1. Detect current implementation

- If inside a worktree, read `.context.*.md` to identify the branch and doc file.
- If a branch slug is provided, look for `.claude/worktrees/{slug}/.context.*.md`.
- If neither works, stop and tell the user no active implementation was found.

### 2. Commit any uncommitted work

- Run `git status` in the worktree.
- If there are staged or unstaged changes, commit them with message: `wip: pause implementation`.
- If clean, skip.

### 3. Save progress snapshot

Update the context file (`.context.{slug}.md`) by appending a `## Progress` section:

```markdown
## Progress

- **Paused**: {current date YYYY-MM-DD}
- **Last commit**: {short SHA and message}
- **Commits on branch**: {count}

### Remaining work

{List any uncompleted acceptance criteria from the doc file — read the doc and find unchecked `- [ ]` items}
```

If a `## Progress` section already exists, replace it.

### 4. Commit the progress snapshot

Commit the updated context file: `chore: save implementation progress snapshot`.

### 5. Report

Tell the user:
- Branch name and worktree path
- Number of commits made so far
- What's been completed vs. what remains
- How to resume: `/implement-continue {slug}`
- The worktree is preserved and ready to resume at any time

### 6. Compact the conversation

After reporting, invoke the `/compact` command to compress the conversation context. This conserves daily rate limit usage.
