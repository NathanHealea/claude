# Release

Merge the pull request (or confirm it was merged), delete the feature branch, update local `main`, and remove the worktree. This is the final step after `/stage` and PR review.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

No arguments required. Run from inside the worktree created by `/implement`.

---

## Context Detection

### 1. Detect remote type

1. Read the project's `CLAUDE.md` and look for a `## Workflow` section. If it contains a **Remote type** field, use that value (`github` or `bitbucket`).
2. If no `## Workflow` section exists, detect from the git remote:
   - Run `git remote get-url origin`
   - If URL contains `github.com` → **github**
   - If URL contains `bitbucket` → **bitbucket**
   - Check `CLAUDE.md` `## Workflow` for a **Bitbucket hosts** field. If the remote URL hostname matches any listed host → **bitbucket**
   - Otherwise → **unknown**
3. Store as **`$REMOTE_TYPE`**.

### 2. Detect docs directory

1. Read `CLAUDE.md` `## Workflow` for a **Docs directory** field. If found, use it.
2. Otherwise: `documents/` if it exists, then `docs/` if it exists, then default `docs`.
3. Store as **`$DOCS_DIR`**.

---

## Steps

### 1. Locate the context file

Find the `.context.*.md` file in the current working directory. There should be exactly one. If none is found, stop and tell the user this command must be run from inside a worktree created by `/implement`.

Read the context file and extract from the `## Staged` section:

- **Branch** — the full branch name
- **Branch slug** — from the `Branch slug` field
- **PR number** — from the `PR number` field
- **PR URL** — from the `PR URL` field
- **Worktree path** — from the `Worktree path` field
- **Merge Into** — from the `Merge Into` field (defaults to `main` if not present)

If the `## Staged` section or required fields are missing, stop and tell the user to run `/stage` first.

### 2. Pre-flight checks

- Confirm the current working directory is inside a worktree (not the main repo). Check with `git rev-parse --show-toplevel` — it should be inside `.claude/worktrees/`.

- **Check PR status** — branch based on `$REMOTE_TYPE`:

#### GitHub (`$REMOTE_TYPE` = `github`)

```bash
gh pr view {PR number} --json state,mergeStateStatus
```

- If `state` is `MERGED` → skip to step 4.
- If `state` is `CLOSED` → stop and tell the user the PR was closed without merging.
- If `state` is `OPEN` → proceed to step 3.

#### Bitbucket (`$REMOTE_TYPE` = `bitbucket`)

Parse the remote URL to extract hostname, project key, and repo slug (same logic as `/stage`).

```bash
curl -s "https://{hostname}/rest/api/1.0/projects/{PROJECT_KEY}/repos/{repo-slug}/pull-requests/{PR number}" \
  -H "Authorization: Bearer ${BITBUCKET_TOKEN}"
```

Parse the response `state` field:
- If `MERGED` → skip to step 4.
- If `OPEN` → stop and tell the user to merge the PR on Bitbucket first. Provide the PR URL.
- If `DECLINED` → stop and tell the user the PR was declined.

#### Unknown (`$REMOTE_TYPE` = `unknown`)

Ask the user: "Has the PR been merged? (The remote type could not be detected, so I can't check automatically.)" Wait for confirmation before proceeding. If not merged, stop.

### 3. Merge the PR

Only applicable for **github** remote type. Bitbucket and unknown require manual merge.

#### GitHub

```bash
gh pr merge {PR number} --squash --delete-branch
```

The `--delete-branch` flag removes the remote branch automatically after merge.

If the merge fails (e.g. merge conflicts, required reviews), stop and report the error. Do not force-merge.

#### Bitbucket / Unknown

Skip this step — the PR was already confirmed as merged in step 2.

### 4. Update local target branch

Determine the main worktree path from `git worktree list` (the first entry) and update the merge target branch:

```bash
git -C {main-worktree-path} checkout {merge-into}
git -C {main-worktree-path} pull
```

### 5. Delete the remote branch

If the remote branch still exists (may not for GitHub with `--delete-branch`, or Bitbucket if auto-delete is configured), remove it:

```bash
git push origin --delete {branch-name}
```

If it's already deleted, skip silently.

### 6. Delete the local branch

Remove the local feature branch:

```bash
git branch -d {branch-name}
```

If `-d` fails because the branch isn't fully merged (can happen with squash merge), use `-D` but warn the user.

### 7. Remove the worktree

Remove the worktree directory:

```bash
git worktree remove {worktree-path}
```

If that fails (e.g. untracked files), tell the user and ask for confirmation before running:

```bash
git worktree remove --force {worktree-path}
```

### 8. Prune worktree list

```bash
git worktree prune
```

### 9. Update the documentation status

If the context file has a `## Documentation` section with a **Doc path**, read that doc file and update its **Status** to `Completed`. Commit this change on `main`.

If there is no doc path, skip silently.

### 10. Report

Tell the user:
- PR #{PR number} has been merged
- Remote and local branch `{branch-name}` deleted
- Worktree removed
- If worktree removal failed, provide the manual cleanup command: `rm -rf {worktree-path}`
- Local `main` is up to date
- Doc status updated (if applicable)
- The work is complete
