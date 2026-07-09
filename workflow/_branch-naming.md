# Workflow Module: Branch Naming

Shared branch-name derivation used by `/plan`, `/implement`, `/implement-continue`, and the
`workflow-runner` agent. Guarantees the same branch name at every phase.

---

## Resolve the branch name

Apply in order (first hit wins):

1. **`$BRANCH_OVERRIDE`** (from the `--branch` flag) — use it directly.
2. The doc's **`**Branch:**`** metadata field, if present and non-empty — use it directly.
3. Derive from the doc **type** and **slug**:
   - **branch slug** — kebab-case derived from the doc filename (strip `.md`) or description,
     3–5 words max (e.g. `admin-profile-linking.md` → `admin-profile-linking`).
   - **prefix** — the doc type, lowercased. If type is missing, default to `feature`.
   - Combine: **`{prefix}/{branch-slug}`**.

## Type → prefix mapping

The branch prefix matches the doc type exactly:

| Doc type                         | Prefix        |
|----------------------------------|---------------|
| `feature`                        | `feature/`    |
| `enhancement`                    | `enhancement/`|
| `refactor`                       | `refactor/`   |
| `bug` / `fix` / `patch`          | matches type  |
| `hotfix`                         | `hotfix/`     |
| `breaking`                       | `breaking/`   |
| (missing / unrecognized)         | `feature/`    |

Examples: `feature/admin-season-delete`, `bug/login-crash`, `refactor/auth-cleanup`.

## Slug reuse

The **branch slug** (the portion after the prefix) is also the worktree directory name
(`.claude/worktrees/{branch-slug}`) and the `.context.{branch-slug}.md` filename. Derive it once
and reuse it everywhere so a feature is addressable by a single slug across all phases.
