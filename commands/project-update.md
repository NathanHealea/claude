# Project Update

Update an existing project's `CLAUDE.md` to include the `## Testing` and `## Workflow` sections required by the unified workflow commands (`/plan`, `/stage`, `/release`, `/list`, `/update-docs`). Detects project context automatically and fills in values.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

No arguments required. Run from the project root.

---

## Steps

### 1. Locate CLAUDE.md

Look for `CLAUDE.md` in the current working directory. If it doesn't exist, stop and tell the user to run `/project-init` or create a `CLAUDE.md` first.

Read the full contents of `CLAUDE.md` and note which sections already exist.

### 2. Detect project context

Gather the following from the project:

#### 2a. Docs directory

1. If `CLAUDE.md` already has a `## Workflow` section with a **Docs directory** field → use that value (already configured).
2. If a `documents/` directory exists at the project root → `documents`
3. If a `docs/` directory exists at the project root → `docs`
4. Otherwise → `docs` (default)

#### 2b. Remote type

1. Run `git remote get-url origin` (if inside a git repo).
2. If URL contains `github.com` → `github`
3. If URL contains `bitbucket` → `bitbucket`
4. Check for known Bitbucket hosts: if the hostname is `git.uoregon.edu` → `bitbucket`
5. If no git remote or unrecognized → `github` (default, note this in the report)

#### 2c. Bitbucket details (only if remote type is bitbucket)

Parse the remote URL to extract:
- **Hostname** (e.g., `git.uoregon.edu`)

Store as the **Bitbucket hosts** value.

#### 2d. PR template

- If remote type is `github` → `github-default`
- If remote type is `bitbucket` → `bitbucket-uo`

#### 2e. Default merge target

1. If `CLAUDE.md` already has a `## Workflow` section with a **Default merge target** field → use that value (already configured).
2. Try to detect from git: run `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null` and extract the branch name (e.g., `refs/remotes/origin/main` → `main`, `refs/remotes/origin/develop` → `develop`).
3. If detection fails → default to `main`.

#### 2f. Package manager

Detect from lock files:
- `bun.lockb` → bun
- `pnpm-lock.yaml` → pnpm
- `yarn.lock` → yarn
- `package-lock.json` or `package.json` → npm
- None → skip

#### 2g. Testing conventions

Scan the project for existing test infrastructure:

1. **Framework detection** — check `package.json` devDependencies for:
   - `vitest` → Vitest
   - `jest` → Jest
   - `@playwright/test` → Playwright
   - `bun` (as runtime with test files) → Bun test
   - None found → `none`

2. **Test file location** — use Glob to find test files:
   - `**/*.test.*` or `**/*.spec.*` → note if colocated with source or in separate directories
   - `__tests__/**` → `__tests__/ directories`
   - `tests/**` or `test/**` → `tests/ directory`
   - None found → leave as placeholder

3. **Naming convention** — from the test files found:
   - Mostly `*.test.*` → `*.test.ts` (or `.tsx`, `.js` as appropriate)
   - Mostly `*.spec.*` → `*.spec.ts`
   - Mixed or none → use the framework's default convention

4. **Mocking patterns** — read 2-3 existing test files (if any) and look for:
   - `vi.mock` → `vi.mock() for services`
   - `jest.mock` → `jest.mock() for services`
   - No mocking found → `none`

5. **Run command** — check `package.json` scripts for a `test` script. Use the detected package manager prefix (e.g., `bun test`, `npm test`, `pnpm test`).

6. **What to test / What NOT to test** — check for:
   - An `analysis/` or `documents/analysis/` or `docs/analysis/` directory → note it as a reference for business rules
   - Existing test patterns that suggest conventions (e.g., integration tests in a specific directory, snapshot tests present or absent)
   - If nothing specific is found, leave as generic guidance

### 3. Determine what to add or update

Compare the detected context against the existing `CLAUDE.md`:

- If `## Testing` section **does not exist** → add it
- If `## Testing` section **exists** → leave it untouched (user has already configured it)
- If `## Workflow` section **does not exist** → add it
- If `## Workflow` section **exists but incomplete** (e.g., missing fields) → add only the missing fields
- If `## Workflow` section **exists and complete** → leave it untouched

Track every change made for the report.

### 4. Update CLAUDE.md

Append the new sections to the end of `CLAUDE.md` (before any trailing whitespace/newlines). Use the exact format below for each section being added:

#### Testing section (if adding)

```markdown
## Testing

- **Framework**: {detected framework}
- **Test location**: {detected location}
- **Naming**: {detected convention}
- **Mocking**: {detected patterns}
- **Run command**: {detected command}

### What to test

- {detected guidance, or "Happy path and error states for all new components"}
- {if analysis docs found: "Consult `{path}/` for business rules and edge cases"}

### What NOT to test

- {detected exclusions, or "No specific exclusions — follow existing test patterns"}
```

#### Workflow section (if adding)

```markdown
## Workflow

- **Docs directory**: `{detected dir}/`
- **Remote type**: `{detected type}`
- **PR template**: `{detected template}`
- **Default merge target**: `{detected branch}`
{if bitbucket: "- **Bitbucket hosts**: `{hostname}`"}
```

### 5. Report

Output a clear summary of what was detected and what changed:

```
## Project Update Summary

### Detected Context
- **Docs directory**: {value} ({how detected — e.g., "found documents/ directory", "from existing CLAUDE.md"})
- **Remote type**: {value} ({how detected — e.g., "parsed from git remote: git@github.com:user/repo.git"})
- **Default merge target**: {value} ({how detected — e.g., "from remote HEAD", "from existing CLAUDE.md", "default"})
- **Package manager**: {value}
- **Test framework**: {value} ({how detected — e.g., "vitest in devDependencies"})
- **Test files found**: {count} ({pattern — e.g., "colocated *.test.tsx files"})

### Changes to CLAUDE.md
- {each change, e.g., "Added ## Testing section with Vitest configuration"}
- {or "## Testing section already exists — skipped"}
- {each change, e.g., "Added ## Workflow section (bitbucket, documents/)"}
- {or "## Workflow section already exists — skipped"}

### Next steps
- Review the new sections in CLAUDE.md and adjust any placeholder values
- The `/plan`, `/stage`, `/release`, `/list`, and `/update-docs` commands will now use these settings
```

If nothing was changed (both sections already exist and are complete), tell the user:
```
CLAUDE.md already has ## Testing and ## Workflow sections — no changes needed.
```
