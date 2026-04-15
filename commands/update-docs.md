# Update Docs

Scan all documentation files and update their status, acceptance criteria, and the overview tracker to reflect the current state of the codebase. Run this after completing work to keep docs in sync.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

Arguments are optional:
- **No arguments**: Scans all doc files and updates everything.
- **Doc file path** (ends with `.md`): Updates only the specified doc file (and the overview).
- **Epic directory** (e.g. `standings-and-leaderboard`): Updates only docs within that epic directory (and the overview).

## Context Detection

### Detect docs directory

1. Read the project's `CLAUDE.md` and look for a `## Workflow` section. If it contains a **Docs directory** field, use that value.
2. If no `## Workflow` section exists, check the filesystem:
   - If a `documents/` directory exists at the project root → use `documents`
   - If a `docs/` directory exists at the project root → use `docs`
   - Otherwise → default to `docs`
3. Store as **`$DOCS_DIR`**.

## Steps

### 1. Gather doc files

#### 1a. Determine scope

- If `$ARGUMENTS` is a path to a specific `.md` file, use only that file.
- If `$ARGUMENTS` is an epic directory name (matches a directory under `$DOCS_DIR/`), gather all `.md` files in that directory.
- If no arguments, gather all `.md` files under `$DOCS_DIR/` (excluding `$DOCS_DIR/overview.md`, `$DOCS_DIR/contributions/`, and `$DOCS_DIR/guides/`).

#### 1b. Filter to actionable docs

Only process docs that have a `**Status:**` field and an `## Acceptance Criteria` section. Skip templates, overview, and any files that don't follow the standard doc format.

### 2. Evaluate each doc

For each doc file, determine its current state by checking the codebase:

#### 2a. Read the doc

Extract:
- **Title** — from the `#` heading
- **Status** — from `**Status:**` field (Todo, In Progress, Completed)
- **Acceptance criteria** — the checklist from `## Acceptance Criteria`
- **Key files** — from the `### Key Files` table (if present)
- **Routes** — from the `## Routes` table (if present)

#### 2b. Verify acceptance criteria against the codebase

For each acceptance criterion:
1. Read the criterion text and identify what it describes (a file, a route, a behavior, a DB migration, etc.)
2. Check the codebase to verify whether the criterion is met:
   - **File exists / was modified**: Use Glob or Grep to confirm the file or pattern exists
   - **Route exists**: Check for the corresponding `page.tsx` or route handler under `src/app/`
   - **Database/migration**: Check `supabase/migrations/` for relevant migration files
   - **Behavior/logic**: Read the relevant source files and verify the described behavior is implemented
3. Mark the criterion as checked (`[x]`) if met, or unchecked (`[ ]`) if not

Be thorough but use judgment — don't mark a criterion as complete unless you have clear evidence in the codebase. When in doubt, leave it unchecked.

#### 2c. Determine new status

Based on the acceptance criteria results:
- **Completed** — All criteria are checked
- **In Progress** — Some (but not all) criteria are checked
- **Todo** — No criteria are checked

### 3. Update each doc file

For each doc where the status or acceptance criteria changed:

1. Update the `**Status:**` field to the new status
2. Update the acceptance criteria checkboxes to match your findings
3. Do NOT modify any other content in the doc (summary, approach, key files, etc.)

### 4. Update the overview

Read `$DOCS_DIR/overview.md` and update the epic scope checklists to match the current state of each doc:

- Each epic has a **High-Level Scope** section with checkboxes linking to doc files
- A scope item should be checked (`[x]`) if the linked doc's status is **Completed**
- A scope item should be unchecked (`[ ]`) if the linked doc's status is **Todo** or **In Progress**

Only update checkboxes for docs that were evaluated. Do not modify other overview content.

### 5. Check for undocumented items

Scan the epic scope lists in `$DOCS_DIR/overview.md` for items that reference doc files. Check if any referenced doc files are missing. If so, report them to the user but do not create new docs.

### 6. Commit

Stage all modified doc files and `$DOCS_DIR/overview.md`. Create a single commit:

```
Update doc status and acceptance criteria
```

If nothing changed, tell the user all docs are already up to date.

### 7. Report

Tell the user:
- How many docs were evaluated
- Which docs had status changes (and what changed, e.g. "In Progress → Completed")
- Which acceptance criteria were updated (brief summary)
- Whether the overview was updated
- Any missing doc files that were referenced but not found
