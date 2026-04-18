# Commit

Write and create a git commit. By default commits all currently staged files; optionally accepts a list of file paths to stage and include.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

- **No arguments** → commit everything already staged.
- **One or more file paths** → `git add` those paths first, then commit only those paths.

---

## Steps

### 1. Resolve what to commit

- If `$ARGUMENTS` is empty:
  - Run `git diff --cached --name-only`. If the output is empty, stop and tell the user there is nothing staged.
- If `$ARGUMENTS` has file paths:
  - Run `git add -- <paths>` for the provided paths.
  - Verify each path exists and is tracked-or-new; if any path is missing, stop and report.

### 2. Gather context for the message

Run in parallel:

- `git status` — see the full working-tree state (never use `-uall`).
- `git diff --cached` — see exactly what will be committed.
- `git log -5 --oneline` — match the repo's commit-message style.

### 3. Draft the commit message

- Use **conventional commit** format: `type(scope): short summary`.
  - Common types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `perf`, `style`.
  - Scope is optional but encouraged when a clear subsystem applies.
- Keep the subject ≤72 characters and focused on the **why**, not a file-by-file what.
- If the change is non-trivial, add a short body (blank line, then 1–3 bullets).
- Do **not** include secrets or credentials. If staged files look like `.env`, credentials, or large binaries, warn the user and stop.

### 4. Review prompt

Print the proposed commit message and prompt the user:

- **yes** — proceed with the commit.
- **adjust/(instruction)** — revise the message per the instruction and re-prompt.
- **no** — stop; do not commit.

Wait for a response. Never auto-commit without explicit approval.

### 5. Commit

On approval, run:

```bash
git commit -m "$(cat <<'EOF'
<approved message>
EOF
)"
```

- Do **not** use `--no-verify` or `--amend`.
- Do **not** push. Pushing is the user's call.
- If a pre-commit hook fails, report the failure, fix the underlying issue if the user asks, and create a **new** commit — never amend.

### 6. Report

Tell the user:

- The new commit SHA (short form) and subject line.
- Any files still unstaged or modified in the working tree (from `git status`).
- A reminder that nothing was pushed.
