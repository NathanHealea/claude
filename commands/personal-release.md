# Release

Merge the pull request, delete the feature branch, update local `main`, and remove the worktree. This is the final step after `/stage` and PR review.

## Steps

### 1. Locate the context file

Find the `.context.*.md` file in the current working directory. There should be exactly one. If none is found, stop and tell the user this command must be run from inside a worktree created by `/implement`.

Read the context file and extract from the `## Staged` section:

- **Branch** — the full branch name
- **Branch slug** — from the `Branch slug` field
- **PR number** — from the `PR number` field
- **PR URL** — from the `PR URL` field
- **Worktree path** — from the `Worktree path` field

If the `## Staged` section or required fields are missing, stop and tell the user to run `/stage` first.

### 2. Pre-flight checks

- Confirm the current working directory is inside a worktree (not the main repo). Check with `git rev-parse --show-toplevel` — it should be inside `.claude/worktrees/`.
- Check the PR status with `gh pr view {PR number} --json state,mergeStateStatus`. Report the current state.
- If the PR is already merged, skip to step 4.
- If the PR is closed (not merged), stop and tell the user.
- If the PR is open, proceed to step 3.

### 3. Merge the PR

Merge the pull request using the **squash** strategy:

```bash
gh pr merge {PR number} --squash --delete-branch
```

The `--delete-branch` flag removes the remote branch automatically after merge.

If the merge fails (e.g. merge conflicts, required reviews), stop and report the error. Do not force-merge.

### 4. Update local main

Determine the main worktree path from `git worktree list` (the first entry) and update it:

```bash
cd {main-worktree-path} && git checkout main && git pull
```

### 5. Delete the local branch

Remove the local feature branch:

```bash
git branch -d {branch-name}
```

If `-d` fails because the branch isn't fully merged (shouldn't happen after squash merge), use `-D` but warn the user.

### 6. Remove the worktree

Remove the worktree directory:

```bash
git worktree remove {worktree-path}
```

If that fails (e.g. untracked files), tell the user and ask for confirmation before running:

```bash
git worktree remove --force {worktree-path}
```

### 7. Prune worktree list

```bash
git worktree prune
```

### 8. Update the documentation status

If the context file has a `## Documentation` section with a **Doc path**, read that doc file and update its **Status** to `Completed`. Commit this change on `main`.

If there is no doc path, skip silently.

### 9. Report

Tell the user:
- PR #{PR number} has been merged
- Remote and local branch `{branch-name}` deleted
- Worktree removed
- Location of the Worktree to be removed manually. Provide command to copy and paste.
- Local `main` is up to date
- Doc status updated (if applicable)
- The work is complete