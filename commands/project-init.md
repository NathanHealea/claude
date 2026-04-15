# Project Init

Initialize a new project directory with a docs structure, a `CLAUDE.md` with workflow and testing configuration, and an `overview.md` derived from the project name and optional context.

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

Generate a `CLAUDE.md` file in the project root (`{project-name}/CLAUDE.md`) using the template below. Use the project name and context to fill in what can be detected or inferred. Leave placeholders for values that require user input.

#### CLAUDE.md Template

````markdown
# {Project Name}

{One-line description derived from context, or "{Describe your project here}"}

## Tech Stack

| Layer | Technology |
|-------|------------|
| {Layer} | {Technology} |

## Project Structure

```
{Key directories and their purpose — generated from initial scan or left as placeholder}
```

## Conventions

- {Coding conventions detected or inferred from context}
- {Naming patterns, file organization rules}
- Commit format: conventional commits (`type(scope): description`)

## Testing

- **Framework**: {Vitest | Bun test | Jest | Playwright | none — inferred from context, or placeholder}
- **Test location**: {colocated `*.test.tsx` | `__tests__/` directories | `tests/` directory}
- **Naming**: {`*.test.ts` | `*.spec.ts`}
- **Mocking**: {mocking patterns, or "none"}
- **Run command**: {`npm test` | `bun test` | `pnpm test`}

### What to test

- {Coverage expectations}
- {Integration vs unit guidance}

### What NOT to test

- {Exclusions, if any}

## Workflow

- **Docs directory**: `{docs|documents}/`
- **Remote type**: `{github|bitbucket}` {detected from git remote, or placeholder}
- **PR template**: `{github-default|bitbucket-uo|custom}`
- **Default merge target**: `{main|develop}` {detected from remote HEAD, or `main`}
````

#### Derivation rules for CLAUDE.md

When **context is provided**:

- **One-line description**: Summarize the project's primary purpose in one sentence.
- **Tech Stack**: Only include rows for technologies explicitly mentioned in the context. Omit layers not mentioned. Common layers: Framework, Styling, UI Components, Backend / Database, Tooling, Infrastructure.
- **Project Structure**: Leave as placeholder (project hasn't been built yet).
- **Conventions**: Infer from the tech stack (e.g., React → component files in PascalCase, Next.js → app router conventions).
- **Testing**: Infer framework from the tech stack (e.g., React + Vite → Vitest, Bun → Bun test). Leave as placeholder if unclear.
- **Workflow**: Set **Docs directory** from the `--docs`/`--documents` flag. Detect **Remote type** from `git remote -v` if inside a git repo, otherwise leave as placeholder. Set **PR template** based on remote type (`github` → `github-default`, `bitbucket` → `bitbucket-uo`). Detect **Default merge target** from `git symbolic-ref refs/remotes/origin/HEAD` if available, otherwise default to `main`.

When **no context is provided**:

- Use the project name as the heading.
- Use `{placeholder}` text in each section for the user to fill in.
- Leave Tech Stack with common layer placeholders.
- Leave Testing with placeholder values.
- Set Workflow docs directory from the flag, leave remote type as placeholder.

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
- A summary of the `CLAUDE.md` content (what was derived vs. what needs to be filled in)
- Highlight the `## Testing` and `## Workflow` sections — explain these drive the `/plan`, `/stage`, and `/release` commands
- A summary of the `overview.md` content (what was derived vs. what needs to be filled in)
- Suggest next steps:
  - Review and refine `CLAUDE.md` (especially Testing and Workflow sections)
  - Review and refine `overview.md`
  - Run `/plan epic <description>` to break epics into implementable feature docs
  - Run `/implement <path/to/doc.md>` to start building
