# Stage

Prepare the current feature branch for release. Automates: build + lint verification, optional version bump, commit, push, and PR creation.

## Steps

### 1. Pre-flight checks

- Confirm we are NOT on `main`. If on `main`, stop and tell the user to switch to a feature branch.
- Detect the package manager (`bun.lockb` → bun, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, default → npm).
- Run the build command. If it fails, stop and report the errors.
- Run the lint command (if a `lint` script exists in `package.json`). If it fails, stop and report the errors.

### 2. Determine version bump (if applicable)

Check if `package.json` exists and has a `version` field. If not, skip to Step 4.

Read the current branch name and determine the version bump type from the prefix:

| Branch prefix | Bump type |
|---------------|-----------|
| `feature/*`   | minor     |
| `fix/*`       | patch     |
| `refactor/*`  | patch     |
| `breaking/*`  | major     |
| anything else | patch     |

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

Create a pull request targeting `main` using `gh pr create`.

First, check for a `.github/PULL_REQUEST_TEMPLATE.md` — if it exists, use it as the body template and fill in the sections. Otherwise, use this format:

Write the PR body to `/tmp/pr-body.txt` using the Write tool, then create the PR:

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
gh pr create --title "<title>" --body-file /tmp/pr-body.txt
```

### 7. Update the context file

Find the `.context.*.md` file in the current working directory. If one exists, append a `## Staged` section:

```markdown
## Staged

- **PR number**: {PR number from gh pr create output}
- **PR URL**: {full PR URL}
- **Version**: {new version, or "N/A" if no bump}
- **Branch slug**: {kebab-case portion after the prefix}
- **Worktree path**: {absolute path from `git rev-parse --show-toplevel`}
- **Staged**: {current date YYYY-MM-DD}
```

If no context file is found, skip silently.

### 8. Update overview (if applicable)

Check if a `docs/overview.md` file exists in the project. If it does:

1. Scan all feature doc files linked from `overview.md`.
2. For each linked doc, read its `**Status:**` field.
3. If the status is `Completed` but the corresponding line in `overview.md` still shows `- [ ]`, update it to `- [x]`.
4. If any lines were updated, amend the commit from Step 4.

If `docs/overview.md` does not exist, skip silently.

### 9. Report

Tell the user:
- The new version number (if bumped)
- A link to the PR (for manual review and merge)
- That the context file has been updated (if applicable)
- Remind them to review the PR, then run `/release` to merge and complete the workflow