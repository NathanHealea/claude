# Stage

Prepare the current feature branch for release. Automates: build + lint verification, optional version bump, commit, push, and PR creation.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

No arguments required. Run from inside the feature branch (main repo or worktree).

---

## Context Detection

### 1. Detect remote type

1. Read the project's `CLAUDE.md` and look for a `## Workflow` section. If it contains a **Remote type** field, use that value (`github` or `bitbucket`).
2. If no `## Workflow` section exists, detect from the git remote:
   - Run `git remote get-url origin`
   - If URL contains `github.com` → **github**
   - If URL contains `bitbucket` → **bitbucket**
   - Check `CLAUDE.md` `## Workflow` for a **Bitbucket hosts** field. If the remote URL hostname matches any listed host → **bitbucket**
   - Otherwise → **unknown** (fallback to manual)
3. Store as **`$REMOTE_TYPE`**.

### 2. Detect PR template preference

1. Read `CLAUDE.md` `## Workflow` for a **PR template** field.
2. If found → store as **`$PR_TEMPLATE`** (`github-default`, `bitbucket-uo`, or `custom`).
3. If not found → infer from `$REMOTE_TYPE`:
   - `github` → `github-default`
   - `bitbucket` → `bitbucket-uo`
   - `unknown` → `github-default`

### 3. Detect docs directory

1. Read `CLAUDE.md` `## Workflow` for a **Docs directory** field. If found, use it.
2. Otherwise: `documents/` if it exists, then `docs/` if it exists, then default `docs`.
3. Store as **`$DOCS_DIR`**.

### 4. Detect merge target

1. Find the `.context.*.md` file in the current working directory.
2. If found, read the **Merge Into** field. Store as **`$MERGE_TARGET`**.
3. If no context file or no **Merge Into** field → check `CLAUDE.md` `## Workflow` for a **Default merge target** field.
4. If still not found → default to `main`.

---

## Steps

### 1. Pre-flight checks

- Confirm we are NOT on `main`. If on `main`, stop and tell the user to switch to a feature branch.
- Detect the package manager (`bun.lockb` → bun, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, default → npm).
- Run the build command. If it fails, stop and report the errors.
- Run the lint command (if a `lint` script exists in `package.json`). If it fails, stop and report the errors.

### 2. Determine version bump (if applicable)

Check if `package.json` exists and has a `version` field. If not, skip to Step 4.

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

### 3. Bump version

Run the version bump using the detected package manager:

```bash
npm version <major|minor|patch> --no-git-tag-version
```

### 4. Commit all changes

Stage all changes (including the version bump if done) and create a commit. The commit message should summarize the work on this branch — look at the branch name, changed files, and recent commits on the branch to write a descriptive message using conventional commit format.

If a version bump was done, include the version number:

```
feat(seasons): add leaderboard page with season filtering (v2.5.0)
```

### 5. Push branch

Push the branch to origin with the `-u` flag:

```bash
git push -u origin <branch-name>
```

### 6. Create PR

Branch based on **`$REMOTE_TYPE`**:

#### 6a. GitHub (`$REMOTE_TYPE` = `github`)

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

#### 6b. Bitbucket (`$REMOTE_TYPE` = `bitbucket`)

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

#### 6c. Unknown (`$REMOTE_TYPE` = `unknown`)

Write the PR body to `/tmp/pr-body.txt` using the GitHub default format. Print the body content and tell the user to create the PR manually on their hosting platform.

### 7. Update the context file

Find the `.context.*.md` file in the current working directory. If one exists, append a `## Staged` section:

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

### 8. Update overview (if applicable)

Check if a `$DOCS_DIR/overview.md` file exists in the project. If it does:

1. Scan all feature doc files linked from `overview.md`.
2. For each linked doc, read its `**Status:**` field.
3. If the status is `Completed` or `Done` but the corresponding line in `overview.md` still shows `- [ ]`, update it to `- [x]`.
4. If any lines were updated, amend the commit from Step 4.

If `$DOCS_DIR/overview.md` does not exist, skip silently.

### 9. Report

Tell the user:
- The new version number (if bumped)
- A link to the PR (for review and merge)
- That the context file has been updated (if applicable)
- Remind them to review the PR, then run `/release` to merge and complete the workflow
