# Workflow Module: Context Detection

Shared project-configuration detection used by `/plan`, `/stage`, `/release`, and the
`workflow-runner` agent. Run only the sections a command needs, and store each result in the
named variable so later steps can reference it.

All routines prefer an explicit `## Workflow` section in the project's `CLAUDE.md`, then fall
back to filesystem/remote inspection.

---

## Detect the docs directory → `$DOCS_DIR`

1. Read the project's `CLAUDE.md` and look for a `## Workflow` section. If it contains a
   **Docs directory** field, use that value.
2. Otherwise, check the filesystem:
   - `documents/` exists at the project root → use `documents`
   - `docs/` exists at the project root → use `docs`
   - Otherwise → default to `docs`
3. Store as **`$DOCS_DIR`**.

## Detect testing conventions → `$TEST_GUIDANCE`

1. Read `CLAUDE.md` and look for a `## Testing` section.
2. If found → store the full section content as **`$TEST_GUIDANCE`** (framework, test location,
   naming, mocking, what to test, what not to test).
3. If not found → scan the codebase for existing test files (`*.test.*`, `*.spec.*`,
   `__tests__/`, `tests/`). Infer framework and conventions from what exists. Store as
   **`$TEST_GUIDANCE`**.
4. If no test files exist either → set **`$TEST_GUIDANCE`** to empty. Unit-test sections are
   skipped downstream.

## Detect remote type → `$REMOTE_TYPE`

1. Read `CLAUDE.md` `## Workflow` for a **Remote type** field (`github` or `bitbucket`). Use it
   if present.
2. Otherwise detect from the git remote:
   - `git remote get-url origin`
   - URL contains `github.com` → **github**
   - URL contains `bitbucket` → **bitbucket**
   - Check `CLAUDE.md` `## Workflow` for a **Bitbucket hosts** field. If the remote URL hostname
     matches any listed host → **bitbucket**
   - Otherwise → **unknown** (fall back to manual PR handling)
3. Store as **`$REMOTE_TYPE`**.

## Detect PR template preference → `$PR_TEMPLATE`

1. Read `CLAUDE.md` `## Workflow` for a **PR template** field. If found → store as
   **`$PR_TEMPLATE`** (`github-default`, `bitbucket-uo`, or `custom`).
2. If not found → infer from `$REMOTE_TYPE`:
   - `github` → `github-default`
   - `bitbucket` → `bitbucket-uo`
   - `unknown` → `github-default`

## Detect merge target → `$MERGE_TARGET`

Resolution order (first hit wins):

1. `--merge-into <name>` flag (see **Parse optional flags** below).
2. The `.context.*.md` file in the current working directory — read its **Merge Into** field.
3. `CLAUDE.md` `## Workflow` → **Default merge target** field.
4. Default to `main`.

Store as **`$MERGE_TARGET`** (also referred to as `$MERGE_INTO` in `/plan`).

## Parse optional flags

Scan `$ARGUMENTS` for these flags (they can appear anywhere). Remove each flag and its value
from the arguments before further parsing.

- `--branch <name>` → **`$BRANCH_OVERRIDE`** (explicit branch name, else empty).
- `--merge-into <name>` → feeds the merge-target resolution above.
