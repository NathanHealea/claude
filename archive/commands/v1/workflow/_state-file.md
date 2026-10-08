# Workflow Module: State File (`.context.*.md`)

The `.context.{branch-slug}.md` file in the worktree root is the **contract** that carries state
across `/implement` → `/implement-pause` → `/implement-continue` → `/stage` → `/release` (and the
`workflow-runner` agent). Each phase reads the sections it needs and appends its own.

There is exactly one context file per worktree. Its filename encodes the branch slug.

---

## Created by `/implement` (base section)

```markdown
# Context: {Doc Title}

- **Type**: {type}
- **Branch**: {branch-name}
- **Merge Into**: {merge-into}
- **Doc directory**: {doc directory}
- **Created**: {current date YYYY-MM-DD}

## Description

{Summary from the doc file}

## Documentation

- **Doc path**: {absolute path to the doc file}
```

## Appended by `/implement-pause` (resume state)

`/implement-pause` ensures the **doc file** has a `**Branch:**` field (so the branch can be
refetched on any machine) and pushes the branch. It may record a `## Progress` section capturing
which steps are done vs. remaining. `/implement-continue` reads `## Progress` if present.

## Appended by `/stage`

```markdown
## Staged

- **PR number**: {PR number from API response or gh output}
- **PR URL**: {full PR URL}
- **Version**: {new version, or "N/A" if no bump}
- **Branch slug**: {kebab-case portion after the prefix}
- **Merge Into**: {$MERGE_TARGET}
- **Worktree path**: {absolute path from `git rev-parse --show-toplevel`}
- **Staged**: {current date YYYY-MM-DD}
```

## Consumed by `/release`

`/release` reads the `## Staged` section (Branch, Branch slug, PR number, PR URL, Worktree path,
Merge Into) plus the `## Documentation` **Doc path**. If the `## Staged` section or its required
fields are missing, `/release` stops and tells the user to run `/stage` first.

---

## Field reference

| Field           | Written by         | Read by                                   |
|-----------------|--------------------|-------------------------------------------|
| Type            | implement          | stage (version bump)                      |
| Branch          | implement          | pause, continue, stage, release           |
| Merge Into      | implement, stage   | stage, release, rebase                    |
| Doc directory   | implement          | plan/overview updates                     |
| Doc path        | implement          | release (status update)                   |
| PR number / URL | stage              | release                                   |
| Version         | stage              | release (tagging)                         |
| Worktree path   | stage              | release (worktree removal)                |
| Branch slug     | stage              | release                                   |

If no context file is found where one is expected, each command handles it per its own rules
(usually: skip silently, or stop and tell the user to run the prior phase).
