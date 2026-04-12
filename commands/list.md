# List

List all documentation files under `docs/` that are not completed, grouped by status.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

Arguments are optional:
- **No arguments**: Lists all non-completed docs across every epic.
- **Epic directory** (e.g. `battle-reports`): Lists non-completed docs only within that epic directory.

## Steps

### 1. Gather doc files

#### 1a. Determine scope

- If `$ARGUMENTS` matches a directory under `docs/`, gather all `.md` files in that directory.
- If no arguments (empty or whitespace), gather all `.md` files under `docs/` recursively.

#### 1b. Filter to actionable docs

Exclude these files from the list:
- `docs/overview.md`
- Anything under `docs/contributions/`
- Anything under `docs/guides/`
- Files without a `**Status:**` field

### 2. Read and categorize each doc

For each doc file:

1. Read the file and extract:
   - **Title** — from the `#` heading
   - **Status** — from `**Status:**` field (Todo, In Progress, Completed)
   - **Epic** — from `**Epic:**` field
   - **Type** — from `**Type:**` field
2. Skip any doc with status **Completed**

### 3. Group and display

Group the remaining docs into two sections: **In Progress** and **Todo**.

Display using this format:

```
## In Progress

| Doc | Epic | Type |
|-----|------|------|
| [Title](relative/path/to/doc.md) | Epic Name | Type |

## Todo

| Doc | Epic | Type |
|-----|------|------|
| [Title](relative/path/to/doc.md) | Epic Name | Type |
```

Rules:
- Show **In Progress** first, then **Todo**
- Within each group, sort alphabetically by epic name, then by title
- If a group has no items, show the heading with "None" underneath
- Use relative paths from the repo root for the doc links (e.g. `docs/seasons/season-participants.md`)

### 4. Summary

After the tables, print a one-line summary:

```
**X in progress, Y todo** (Z completed docs hidden)
```

Where Z is the count of docs that were skipped because their status was Completed.