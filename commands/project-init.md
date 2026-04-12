# Project Init

Initialize a new project directory with a docs structure and an `overview.md` derived from the project name and optional context.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

### Parsing

Extract the following from `$ARGUMENTS`:

1. **Project name** (required) — the first argument. This becomes the project directory name.
2. **Context** (optional) — a quoted string providing contextual information about the project (features, UI, implementation, data, etc.).
3. **Flags** — check for `--documents` anywhere in the arguments. If absent, default to `--docs`.

If no arguments are provided, stop and ask the user for a project name.

### Examples of valid input

```
/project-init my-app
/project-init my-app "React dashboard with auth, dark mode, and REST API integration"
/project-init my-app --documents
/project-init my-app "ETL pipeline using Python, PostgreSQL source, S3 destination" --documents
```

---

## Behavior

### 1. Determine the docs directory name

- If `--documents` is present in `$ARGUMENTS` → use `documents`
- Otherwise → use `docs` (default)

### 2. Create the project structure

Create the project directory and the docs directory inside it, relative to the current working directory:

```
{project-name}/
  CLAUDE.md
  {docs|documents}/
```

### 3. Generate `CLAUDE.md`

Generate a `CLAUDE.md` file in the project root (`{project-name}/CLAUDE.md`). Use the project name and context to write project-level instructions for Claude Code. The file should include:

- A brief description of what the project is
- Key conventions derived from the context (tech stack, file structure, coding patterns)
- The docs directory location (`docs/` or `documents/`)
- Any relevant guidance that would help Claude Code work effectively in this project

Use the same context provided to `/project-init` to inform the content. If no context is provided, generate a minimal `CLAUDE.md` with the project name and placeholder sections.

### 4. Generate `overview.md`

Create `{project-name}/{docs|documents}/overview.md` following the template and derivation rules below.

---

## Generated File: `overview.md`

### Template

```markdown
# Project Overview

**{Project Name}** — {one-line description derived from context, or placeholder}

## What It Does

{Derived from context: primary features, target users, core functionality. If no context provided, leave as a placeholder for the user to fill in.}

## Tech Stack

| Layer | Technology |
|---|---|
| **{Layer}** | {Technology} |

---

## Status Key

| Status | Description |
|---|---|
| **Todo** | Not started — no acceptance criteria completed |
| **In Progress** | Partially implemented — some acceptance criteria completed |
| **Completed** | Fully implemented — all acceptance criteria completed |

## Implementation Order

<!-- Recommended sequence for building the MVP epics -->

1. {Epic name} — {rationale for ordering}
2. {Epic name} — {rationale for ordering}

## MVP Features (Epics)

<!--
Epic Template:

### Epic: [Name]
**Goal:** [What this epic delivers to the user]

**High-Level Scope:**
- [ ] [Feature or user story](./epic-name/feature-name.md)
-->

### Epic: {Epic Name}

**Goal:** {What this epic delivers}

**High-Level Scope:**

- [ ] [Feature or user story](./epic-name/feature-name.md)
```

### Derivation Rules

When **context is provided**, derive content from it:

- **One-line description**: Summarize the project's primary purpose in one sentence.
- **What It Does**: Summarize the primary features, target users, and core functionality.
- **Tech Stack**: Only include rows for technologies explicitly mentioned in the context. Omit layers that aren't mentioned. Common layers: Framework, Styling, UI Components, Backend / Database, Tooling, Infrastructure.
- **Implementation Order**: Suggest a logical build sequence based on dependencies between the derived epics.
- **MVP Features (Epics)**: Break the context into distinct feature areas. Each becomes an epic with a goal and scoped user stories. Feature files are linked but not created.

When **no context is provided**, generate the file with:

- The project name as the heading
- Placeholder text in each section for the user to fill in (e.g., `{Describe what the project does}`)
- An empty Tech Stack table with common layer placeholders
- A single placeholder epic

---

## 5. Report

Tell the user:

- The project directory path and structure created
- A summary of the `CLAUDE.md` content
- A summary of the `overview.md` content (what was derived vs. what needs to be filled in)
- Suggest next steps:
  - Review and refine `CLAUDE.md` and `overview.md`
  - Run `/plan epic <description>` to break epics into implementable feature docs
  - Run `/implement <path/to/doc.md>` to start building
