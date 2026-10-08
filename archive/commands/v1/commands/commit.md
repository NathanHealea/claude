# Commit

Write and create one or more git commits. Analyzes all changed files, groups them into logical commits, and stages + commits each group in a sensible order.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

- **No arguments** → collect all staged and unstaged changes.
- **One or more file paths** → scope the commit to only those paths.

---

## Steps

### 1. Collect changed files

Run `git status` (never `-uall`) to get the full working-tree state.

- If `$ARGUMENTS` has file paths: verify each exists; if any are missing, stop and report. Work only with those files.
- If `$ARGUMENTS` is empty: work with all staged, unstaged-modified, and untracked files.

If there are no changes at all, stop and tell the user.

Check for secrets: if any file looks like `.env`, credentials, or large binaries, warn the user and stop.

### 2. Group files into logical commits

Analyze the file paths (and content where helpful) and group them into one or more logical commits. Apply this priority order when multiple groups exist — commit earlier groups first:

| Priority | Category | Examples |
|----------|----------|---------|
| 1 | **Dependencies** | `package.json`, lock files, `requirements.txt`, `go.mod` |
| 2 | **Configuration / tooling** | config files, `.gitignore`, CI/CD, lint/build tooling |
| 3 | **Core source / feature** | `src/`, `lib/`, `app/`, domain code |
| 4 | **Tests** | `*.test.*`, `*.spec.*`, `__tests__/`, `test/` |
| 5 | **Documentation** | `*.md`, `docs/`, `CHANGELOG` |
| 6 | **Miscellaneous** | anything that doesn't fit above |

Within a category, files that belong to the same feature or subsystem should stay in the same commit. If all changes clearly belong to a single logical unit, produce one commit.

### 3. Present proposed grouping

Before doing anything, display the plan to the user:

```
Proposed commits (in order):

1. chore(deps): ... — package.json, package-lock.json
2. feat(auth): ... — src/auth/login.ts, src/auth/token.ts
3. test(auth): ... — src/auth/login.test.ts
```

Prompt:
- **yes** — proceed with all commits as shown.
- **adjust/(instruction)** — revise grouping or messages per the instruction and re-display.
- **no** — stop; do not commit anything.

Wait for a response before proceeding.

### 4. Commit each group in order

For each group (in the approved order):

1. Stage only the files in this group:
   ```bash
   git add -- <file1> <file2> ...
   ```
2. Run:
   ```bash
   git commit -m "$(cat <<'EOF'
   <message>
   EOF
   )"
   ```
3. If a pre-commit hook fails: report the failure. If the user asks to fix it, do so and create a **new** commit — never amend. If they don't, stop.

Do **not** use `--no-verify` or `--amend`. Do **not** push.

### 5. Report

After all commits are done, tell the user:

- Each commit SHA (short form) and subject line, in order.
- Any files still unstaged or modified in the working tree.
- A reminder that nothing was pushed.
