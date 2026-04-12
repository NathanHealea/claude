# Plan

Create or update a documentation file with the implementation plan for a work item. Supports three modes:

1. **Epic mode** — `/plan epic <description>` — Creates a new epic directory with feature docs for each identified feature.
2. **New doc mode** — `/plan <type> <description>` — Explores the codebase, designs the approach, creates a new doc.
3. **Existing doc mode** — `/plan <path/to/doc.md>` — Reads an existing doc as context, explores the codebase, and updates the doc with an implementation plan.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

### Detecting the mode

- If `$ARGUMENTS` ends with `.md` and the file exists on disk → **Existing doc mode**
- If the first word of `$ARGUMENTS` is `epic` (case-insensitive) → **Epic mode**
- Otherwise → **New doc mode** (first word is the type, rest is the description)

If no arguments are provided, ask the user for the work type and description.

---

## Epic Mode

### Usage

```
/plan epic <description of the epic>
```

Optionally append extra context after `--`:

```
/plan epic User Authentication and Registration using Supabase -- should support email/password, OAuth, and session management
```

### Steps

#### 1. Parse input

Extract the **description** (everything after `epic`, up to `--` if present). If `--` is present, capture everything after it as **extra context**.

Generate an **epic slug** from the description: a short kebab-case slug (2-4 words max), e.g. `user-authentication`.

Generate a human-readable **epic name** from the description, e.g. `User Authentication`.

#### 2. Explore the codebase

Based on the full context (description + extra context), explore the codebase to understand:
- What files and components already exist that are relevant
- Existing patterns and conventions that apply
- Dependencies, packages, and configuration already in place
- The current project architecture and how this epic fits in

Use Glob, Grep, and Read tools to investigate. Be thorough — this exploration informs the feature breakdown.

#### 3. Break down into features

Analyze the epic description and codebase context to identify the individual features needed. Each feature should be:
- A **single, implementable unit of work** (could be done in one PR)
- **Ordered by dependency** (foundation features first, dependent features later)
- Scoped to a clear deliverable

For each feature, determine:
- **Title** — human-readable name
- **Doc slug** — kebab-case filename (3-5 words max)
- **Type** — typically `feature`, but could be `enhancement` or `refactor`
- **Summary** — 1-2 sentence description
- **Acceptance criteria** — checklist of what "done" looks like
- **Implementation plan** — step-by-step plan for that feature (what files to create/modify, how to implement, order of operations, risks)

#### 4. Create the epic directory

Create the directory: `docs/{epic-slug}/`

#### 5. Create feature documentation files

For each feature identified in Step 3, create a doc file at `docs/{epic-slug}/{feature-slug}.md` with the following structure:

```markdown
# {Feature Title}

**Epic:** {Epic Name}
**Type:** {Type}
**Status:** Todo

## Summary

{Feature summary}

## Acceptance Criteria

- [ ] {criterion 1}
- [ ] {criterion 2}
- ...

## Implementation Plan

{Step-by-step implementation plan for this feature}

### Affected Files

| File | Changes |
|------|---------|
| {file path} | {description of changes} |

### Risks & Considerations

- {risk or consideration}
```

If a template exists at `docs/contributions/templates/feature.md`, use it as the base structure and fill in the fields. If no template exists, use the structure above.

#### 6. Update the overview

If `docs/overview.md` exists:

1. **Add the epic to the MVP Features (Epics) section** — Find the ordered epic list and the epic sections. Determine the next epic number by reading the existing epics. Add a new epic section following the existing pattern:

   ```markdown
   ## Epic {N}: {Epic Name}

   **Goal:** {One-sentence goal derived from the epic description}

   **High-Level Scope:**

   - [ ] [{Feature Title}](./{epic-slug}/{feature-slug}.md)
   - [ ] [{Feature Title}](./{epic-slug}/{feature-slug}.md)
   ```

   Also add the epic to the **Implementation Order** table if one exists.

2. **Add to the Features (Epics) section** — Add a new subsection with a feature table:

   ```markdown
   ### {Epic Name}

   | | Name | Type | Status |
   |---|------|------|--------|
   | [ ] | [{Feature Title}](./{epic-slug}/{feature-slug}.md) | Feature | Todo |
   | [ ] | [{Feature Title}](./{epic-slug}/{feature-slug}.md) | Feature | Todo |
   ```

3. Do not modify any other sections of the overview.

#### 7. Stage and commit

Stage all new doc files and the updated overview:

```bash
git add docs/
git commit -m "docs({epic-slug}): add {epic name} epic with feature docs"
```

#### 8. Report

Tell the user:
- The epic directory path and number of feature docs created
- A brief summary of each feature (title + one-line description)
- That the overview has been updated
- Suggest they review the docs, then run `/implement {doc-path}` on each feature to start working (in order)

---

## New Doc Mode

### Usage

```
/plan <type> <description of work>
```

Optionally append extra context after `--`:

```
/plan feature add user profiles -- should support avatar uploads and bio field
```

Valid types:

| Type | Template |
|------|----------|
| `epic` | *(special mode — see Epic Mode above)* |
| `feature` | `docs/contributions/templates/feature.md` |
| `bug` | `docs/contributions/templates/bug.md` |
| `fix` | `docs/contributions/templates/bug.md` |
| `patch` | `docs/contributions/templates/bug.md` |
| `refactor` | `docs/contributions/templates/enhancement.md` |
| `enhancement` | `docs/contributions/templates/enhancement.md` |
| `hotfix` | `docs/contributions/templates/bug.md` |

If the type is not recognized, stop and tell the user the valid types.

### Steps

#### 1. Parse input

Extract the **type** (first word) and the **description** (remaining words, up to `--` if present) from `$ARGUMENTS`. If `--` is present, capture everything after it as **extra context**.

Generate a **doc slug** from the description: a short kebab-case slug (3-5 words max), e.g. `admin-season-delete`.

#### 2. Determine doc directory

Analyze the **description** to determine which epic directory the documentation should live in.

**Rules:**
1. Read the existing directories under `docs/` (exclude `contributions/` and `overview.md`)
2. Match the description to the most relevant epic directory based on the subject matter
3. If no existing directory is a good fit, use `docs/other/`
4. If the work clearly warrants a new epic directory, create one with a kebab-case name — but prefer existing directories when reasonable

Set the following values for use in later steps:
- **Type**: The parsed type
- **Description**: The remaining words after the type
- **Extra context**: Anything after `--` (if provided)
- **Doc slug**: The generated kebab-case slug
- **Doc directory**: The determined epic directory (e.g. `docs/seasons/`, `docs/other/`)

#### 3. Explore the codebase

Based on the full context (description + extra context), explore the codebase to understand:
- What files and components are relevant to this work
- Existing patterns and conventions that apply
- Dependencies and relationships between the affected areas
- Any potential risks or considerations

Use Glob, Grep, and Read tools to investigate. Be thorough — this exploration informs the plan.

#### 4. Create the implementation plan

Think through the work and create a step-by-step implementation plan that covers:
- **What** needs to change (specific files, components, database schema, etc.)
- **How** each change should be implemented
- **Order** of operations (what depends on what)
- **Risks** or things to watch out for

#### 5. Create the documentation file

Determine the full path: `{doc directory}/{doc-slug}.md`

1. Read the appropriate template from `docs/contributions/templates/` based on the **type** (see table above).
2. Copy the template content to the target path.
3. Pre-fill the following fields:
   - **Title** — A human-readable title derived from the context.
   - **Epic** — The epic name derived from the doc directory (e.g., `docs/seasons/` → `Seasons`).
   - **Summary / Description** — A clear summary based on the gathered context (including extra context if provided).
   - **Status** — Set to `Todo`.
   - **Implementation plan** — The step-by-step plan from Step 4. If the template doesn't have an explicit "Implementation" section, add one.
4. Fill in as much of the template as possible from the codebase exploration — acceptance criteria, affected files, technical details, etc.

#### 6. Update the overview

If `docs/overview.md` exists, update the **Features (Epics)** section to include the new doc:

1. Read `docs/overview.md` and find the `## Features (Epics)` section.
2. Determine which epic subsection the doc belongs to based on the **doc directory**:
   - `docs/paint-information/` → `### Paint Information`
   - `docs/color-wheel-visualization/` → `### Color Wheel Visualization`
   - `docs/ui-and-layout/` → `### UI & Layout`
   - `docs/brand-features/` → `### Brand Features`
   - `docs/color-analysis/` → `### Color Analysis`
   - Any other directory → `### Other`
3. If the epic subsection exists, append a new row to its table:
   ```
   | [ ] | [Doc Title](./relative/path/to/doc.md) | Type | Todo |
   ```
4. If the epic subsection does not exist, create it with a new table:
   ```markdown
   ### Epic Name

   | | Name | Type | Status |
   |---|------|------|--------|
   | [ ] | [Doc Title](./relative/path/to/doc.md) | Type | Todo |
   ```
5. Do not modify any other sections of the overview.

#### 7. Stage and commit

Stage the new doc file and the updated overview:

```bash
git add docs/
git commit -m "Add {type} doc: {title}"
```

#### 8. Report

Tell the user:
- The doc file path
- A summary of the implementation plan
- That the overview has been updated
- Suggest they review the doc, then run `/implement {doc-path}` to create a worktree and start working

---

## Existing Doc Mode

### Usage

```
/plan <path/to/doc.md>
```

The document is used as context — its title, description, acceptance criteria, and any existing content inform the plan. **No new document is created.**

### Steps

#### 1. Read the document

Read the file at the provided path. Extract:
- **Title**
- **Description / Summary**
- **Acceptance criteria** (if present)
- **Any existing notes or context**

#### 2. Explore the codebase

Based on the document content, explore the codebase to understand:
- What files and components are relevant to this work
- Existing patterns and conventions that apply
- Dependencies and relationships between the affected areas
- Any potential risks or considerations

Use Glob, Grep, and Read tools to investigate. Be thorough — this exploration informs the plan.

#### 3. Create the implementation plan

Think through the work and create a step-by-step implementation plan that covers:
- **What** needs to change (specific files, components, database schema, etc.)
- **How** each change should be implemented
- **Order** of operations (what depends on what)
- **Risks** or things to watch out for

#### 4. Update the document

Write the implementation plan into the existing document:
- If the document has an **Implementation** or **Implementation Plan** section, replace its content.
- Otherwise, append an `## Implementation Plan` section at the end.
- Do **not** modify the rest of the document (title, description, acceptance criteria, etc.) unless corrections are needed.

#### 5. Stage and commit

Stage the updated doc file and create a commit:

```bash
git add {doc-path}
git commit -m "Add implementation plan to {doc filename}"
```

#### 6. Report

Tell the user:
- A summary of the implementation plan
- That the doc has been updated in place
- Suggest they review the plan, then run `/implement {doc-path}` to create a worktree and start working