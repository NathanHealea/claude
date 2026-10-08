# Work item workflow skills

Four global Claude Code skills implementing an Agile work item workflow:

| Phase | Skill | Produces |
|---|---|---|
| 1. Plan | `plan-work-item` | A work item document — description, requirements, test plan, implementation plan. Stops for approval. |
| 2. Implement | `implement-work-item` | A worktree, a branch, and commits that execute the documented plan. |
| 3. Stage | `stage-work-item` | A verified, self-reviewed, pushed branch with version + changelog, and a review artifact. |
| 4. Release | `release-work-item` | A merge, a tag, cleanup, and a closed-out document. |

The skills are written generically. Anything project-specific lives in that
project's `CLAUDE.md`, which overrides every default.

## Install

Copy the four skill folders into your global skills directory:

```
~/.claude/skills/plan-work-item/SKILL.md
~/.claude/skills/plan-work-item/templates/work-item.md
~/.claude/skills/plan-work-item/templates/epic.md
~/.claude/skills/implement-work-item/SKILL.md
~/.claude/skills/stage-work-item/SKILL.md
~/.claude/skills/release-work-item/SKILL.md
```

Each is invocable by name (`/plan-work-item`) or triggered by its description.

## Work item types

- **epic** — a large body of work, decomposed into children. Lives at
  `docs/<epic>/epic-<slug>.md`.
- **story** — new or changed observable behavior.
- **bug** — existing behavior that is wrong. Requires a regression test.
- **task** — necessary work with no observable behavior change.

Default document path: `docs/<epic>/<type>-<slug>.md`, or
`docs/<type>-<slug>.md` when the item has no parent epic.

## Project configuration

Add a `## Work Item Workflow` section to the project's `CLAUDE.md`. Every key
is optional; omitted keys use the default silently.

The block below shows **example values for a Node project**, not the defaults.
The defaults live in each skill's own configuration table — several of them are
"detect from the project" rather than a fixed value, so writing a value here
replaces detection rather than confirming it.

```markdown
## Work Item Workflow

### Documents
- work_items_root: docs
- work_item_path: <work_items_root>/<epic>/<type>-<slug>.md
- types: epic, story, bug, task
- slug: kebab-case from the title, 2-5 words
- doc_template: .claude/templates/work-item.md   # overrides the skill's own template
- epic_template: .claude/templates/epic.md        # overrides the skill's own template
- requirement_id_prefix: R                        # tests T, acceptance criteria AC

### Branching
- branch_pattern: <type>/<slug>
- base_branch: main
- worktree: enabled
- worktree_path: ../<repo>-worktrees/<type>-<slug>

### Verification
- verify_commands:          # example: a Node project. Use your own commands.
  - npm test
  - npm run lint
  - npm run typecheck
  - npm run build

### Commits
- commit_style: conventional
- commit_granularity: one commit per implementation-plan step

### Review
- review_mode: report        # report | pr | patch | none
- pr_location:               # repo or URL, only when review_mode is pr
- pr_template: .github/pull_request_template.md

### Versioning
- changelog: CHANGELOG.md
- changelog_format: keep-a-changelog
- version_files: package.json
- version_policy: semver     # breaking -> major, story -> minor, bug/task -> patch

### Release
- merge_strategy: squash     # squash | merge | rebase
- tag_releases: true
- tag_pattern: v<version>
- delete_branch_after_merge: true
- deploy_command:            # omit to keep deployment out of the workflow
```

Placeholders used throughout: `<repo>` is the repository directory name,
`<epic>` the epic folder, `<type>` the work item type, `<slug>` the kebab-case
title.

Also put in `CLAUDE.md` the things the skills deliberately do not guess: code
style, architecture rules, directory layout, test framework conventions, and
anything the project forbids.

## Phase boundaries

The phases are deliberately separated so each stop is a real decision point.

- Plan writes no code and does not proceed without approval.
- Implement does not push, open a PR, bump a version, or touch the changelog.
- Stage does not merge, tag, or deploy.
- Release does not author the version bump or changelog entry — those were
  reviewed as part of the change. It promotes them, merges, tags, and cleans up.

A work item's `status` moves `planned → in-progress → staged → released`, with
`changes-requested` as the way back from Stage to Implement when a review asks
for changes.
