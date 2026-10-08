# Workflow Module: Commit Conventions

Shared commit rules used by every phase that creates a commit. Consistent with the global
`CLAUDE.md` git rules.

---

## Format

Use Conventional Commit format: `type(scope): description`.

- `type` — `feat`, `fix`, `docs`, `refactor`, `chore`, etc.
- `scope` — the feature area / epic slug where meaningful.
- When a version bump was applied, append it: `feat(seasons): add leaderboard page (v2.5.0)`.

## Authoring the commit message

- **Single-line:** `git -C {worktree} commit -m "..."`.
- **Multi-line:** write the message to `/tmp/commit-msg.txt` with the Write tool, then
  `git -C {worktree} commit -F /tmp/commit-msg.txt`.
- **Never** use HEREDOC or `$(...)` command substitution in commit commands.

## Staging

Stage only the files that belong to the change being committed
(`git -C {worktree} add {files}`) — never blanket-stage unrelated working-tree changes.

## Hard rules (from global CLAUDE.md)

- **Never** include a `Co-Authored-By: Claude` trailer or any Claude/Anthropic co-author line.
- **Never** add Claude as a git author or committer.
- **Never auto-commit in interactive mode** — a commit happens only after the user approves the
  step (see `_interactive-loop.md`). In `auto` mode the loop commits each group without
  prompting.

## Worktree command hygiene

When operating on a worktree, **always** use `git -C {worktree}` / `--prefix {worktree}` /
absolute paths. Never chain commands with `&&`, `||`, or `;`.
