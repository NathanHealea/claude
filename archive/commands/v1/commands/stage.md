# Stage

Prepare the current feature branch for release. Automates: build + lint verification, optional version bump, commit, push, and PR creation.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

No arguments required. Run from inside the feature branch (main repo or worktree).

---

## Context Detection

Detect project configuration by reading and following
**`~/.claude/workflow/_context-detection.md`**. Run these routines and store the results:

- **Detect remote type** → `$REMOTE_TYPE` (`github`, `bitbucket`, or `unknown`)
- **Detect PR template preference** → `$PR_TEMPLATE`
- **Detect docs directory** → `$DOCS_DIR`
- **Detect merge target** → `$MERGE_TARGET`

---

## Steps

### 1. Verify branch is rebased

1. Determine `$REBASE_SOURCE` using the same logic as `/rebase` Step 1: `$ARGUMENTS` → `.context.*.md` **Merge Into** field → `main`.
2. Run `git fetch origin $REBASE_SOURCE`.
3. Run `git log HEAD..origin/$REBASE_SOURCE --oneline`.
4. If the output is **empty**, the branch is up to date — continue to Step 2.
5. If the output is **non-empty**, the branch is behind `origin/$REBASE_SOURCE`. Follow the `/rebase` command workflow (Steps 4–7) to rebase before continuing. If the rebase is aborted, stop `/stage`.

### 2. Update overview document (if applicable)

Check if a `$DOCS_DIR/overview.md` file exists in the project. If it does:

1. Identify the current feature by reading the `.context.*.md` file (use the slug in the filename or the **Branch slug** / feature name inside the file). If no context file exists, derive the feature name from the current branch name.
2. Scan `overview.md` for a `- [ ]` entry whose text or linked document name matches the current feature.
3. If a matching unchecked entry is found, update it to `- [x]`.
4. If the linked feature doc exists, also confirm its `**Status:**` field is `Completed` or `Done`; if not, update it.
5. Stage and commit the overview change with a message like:

   ```
   docs: mark <feature-name> as completed in overview
   ```

If `$DOCS_DIR/overview.md` does not exist, skip silently.

### 3. Pre-flight checks

- Confirm we are NOT on `main`. If on `main`, stop and tell the user to switch to a feature branch.
- Detect the package manager (`bun.lockb` → bun, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, default → npm).
- Run the build command. If it fails, stop and report the errors.
- Run the lint command (if a `lint` script exists in `package.json`). If it fails, stop and report the errors.

### 4. Determine version bump (if applicable)

Check if `package.json` exists and has a `version` field. If not, skip to Step 6.

Read the current branch name and determine the version bump type from the prefix:

| Branch prefix      | Bump type |
|--------------------|-----------|
| `feature/*`        | minor     |
| `enhancement/*`    | minor     |
| `bug/*`            | patch     |
| `fix/*`            | patch     |
| `patch/*`          | patch     |
| `hotfix/*`         | patch     |
| `refactor/*`       | patch     |
| `breaking/*`       | major     |
| anything else      | patch     |

### 5. Bump version

Run the version bump using the detected package manager:

```bash
npm version <major|minor|patch> --no-git-tag-version
```

### 6. Commit all changes

Stage all changes (including the version bump if done) and create a commit following
**`~/.claude/workflow/_commit-conventions.md`**. The commit message should summarize the work on
this branch — look at the branch name, changed files, and recent commits on the branch to write a
descriptive message using conventional commit format.

If a version bump was done, include the version number:

```
feat(seasons): add leaderboard page with season filtering (v2.5.0)
```

### 7. Push branch

Push the branch to origin with the `-u` flag:

```bash
git push -u origin <branch-name>
```

### 8. Create PR

Branch based on **`$REMOTE_TYPE`**:

#### 8a. GitHub (`$REMOTE_TYPE` = `github`)

Check for a `.github/PULL_REQUEST_TEMPLATE.md` — if it exists, use it as the body template and fill in the sections. Otherwise, use the default format.

Write the PR body to `/tmp/pr-body.txt` using the Write tool:

```
## Summary
<bullet points summarizing ALL changes on the branch, not just the last commit>

## Version
<old version> -> <new version> (<bump type>)
(omit this section if no version bump was done)

## Test plan
- [ ] Build passes
- [ ] Lint passes

Generated with [Claude Code](https://claude.com/claude-code)
```

```bash
gh pr create --title "<title>" --body-file /tmp/pr-body.txt --base $MERGE_TARGET
```

#### 8b. Bitbucket (`$REMOTE_TYPE` = `bitbucket`)

Parse the remote URL to extract the project key and repo slug dynamically:
- Read `git remote get-url origin`
- Extract the path segments (e.g., `ssh://git@host/projectdir/repo.git` → project key = uppercase of `projectdir`, repo slug = `repo`)
- API base: `https://{hostname}/rest/api/1.0`

The API requires a personal access token. Read it from the `BITBUCKET_TOKEN` environment variable. If not set, check `~/.bitbucket-token` or `~/.config/bitbucket/token`. If no token is found, fall back to outputting the PR body and a manual creation link.

Write the PR body to `/tmp/pr-body.txt`:

```
*Primary Reviewer(s):*
*Review By:*

**Overview**
<1-3 sentence summary of what this branch does>

**Details**
<bullet points summarizing ALL changes on the branch, not just the last commit>

**Screenshots**
*Before*


*After*


**Testing**
- [ ] Build passes
- [ ] Lint passes

*Testing Environment Link:*
```

Write the JSON payload to `/tmp/pr-payload.json`:

```json
{
  "title": "<PR title>",
  "description": "<contents of /tmp/pr-body.txt>",
  "fromRef": {
    "id": "refs/heads/<branch-name>"
  },
  "toRef": {
    "id": "refs/heads/$MERGE_TARGET"
  }
}
```

```bash
curl -s -X POST \
  "https://{hostname}/rest/api/1.0/projects/{PROJECT_KEY}/repos/{repo-slug}/pull-requests" \
  -H "Authorization: Bearer ${BITBUCKET_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @/tmp/pr-payload.json
```

Parse the response JSON to extract the PR number (`.id`) and construct the PR URL:
```
https://{hostname}/projects/{PROJECT_KEY}/repos/{repo-slug}/pull-requests/<id>
```

If the API call fails (no token, auth error, network error), fall back to providing the manual creation link:
```
https://{hostname}/projects/{PROJECT_KEY}/repos/{repo-slug}/pull-requests?create&sourceBranch=refs%2Fheads%2F<branch-name>
```

#### 8c. Unknown (`$REMOTE_TYPE` = `unknown`)

Write the PR body to `/tmp/pr-body.txt` using the GitHub default format. Print the body content and tell the user to create the PR manually on their hosting platform.

### 9. Update the context file

Find the `.context.*.md` file in the current working directory (schema:
`~/.claude/workflow/_state-file.md`). If one exists, append a `## Staged` section:

```markdown
## Staged

- **PR number**: {PR number from API response or gh output}
- **PR URL**: {full PR URL}
- **Version**: {new version, or "N/A" if no bump}
- **Branch slug**: {kebab-case portion after the prefix}
- **Merge Into**: {$MERGE_TARGET}
- **Worktree path**: {absolute path from `git rev-parse --show-toplevel`}
- **Staged**: {current date YYYY-MM-DD}
```

If no context file is found, skip silently.

### 10. Report

Tell the user:
- The new version number (if bumped)
- A link to the PR (for review and merge)
- That the context file has been updated (if applicable)
- Remind them to review the PR, then run `/release` to merge and complete the workflow

### 11. Compact the conversation

After reporting, invoke the `/compact` command to compress the conversation context. This conserves daily rate limit usage.
