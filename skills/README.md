# wi — work item workflow

Plan → Build → Stage → Release, driven by one CLI that you and agents both run.

- `bin/wi` does the mechanics: documents, branches, worktrees, verification,
  version bumps, merges, tags, cleanup. It is deterministic and needs only bash,
  git, sed, and awk.
- `skills/wi-*` do the judgment: planning, test-first building, review triage,
  changelog writing. Every mechanical step they take is a `wi` command.
- `agents/` are the specialists the skills spawn: `test-engineer` writes failing
  tests and runs mutation checks; `code-reviewer`, `security-auditor`, and
  `a11y-privacy-auditor` review the staged diff in parallel.

## Where it lives

```
~/.claude/skills/wi-{plan,build,stage,release,auto}/   skills
~/.claude/agents/{test-engineer,code-reviewer,security-auditor,a11y-privacy-auditor}.md
~/.claude/workflow/bin/wi                               CLI
~/.claude/workflow/templates/                           work item and epic templates
~/.local/bin/wi -> ~/.claude/workflow/bin/wi            on PATH
~/.claude/archive/commands/                             the previous four-skill workflow
```

`wi` finds its templates relative to its real path, so keep `bin/` and
`templates/` side by side. The reviewer agents read
`~/.claude/skills/review-code/references/`, so keep `review-code` installed.

## Two ways to run it

Autonomous — two human interactions:

```
/wi-auto Add CSV export to the advising report
   … agent plans, ends turn with the summary
you: approved
   … agent builds every step test-first, stages, reviews, fixes, ends turn with
     the stage report and the release dry run
you: accept
   … agent releases
```

By hand, or one phase at a time — the same commands the agent runs:

| Step | You run | Or ask an agent for |
|---|---|---|
| Write the plan | `wi new story "Add CSV export"`, then edit the document | `/wi-plan` |
| Approve the plan | `wi approve add-csv-export` | say "approved" |
| Start | `wi start add-csv-export` → prints the worktree | `/wi-build` |
| Work a step | `wi next add-csv-export`, code, `wi verify --quick`, commit, `wi tick add-csv-export 1` | `/wi-build` |
| Check everything | `wi verify` | |
| Sync with base | `wi sync add-csv-export` | `/wi-stage` |
| Stage | add the changelog entry, `wi stage add-csv-export [--push]` | `/wi-stage` |
| See the release plan | `wi release add-csv-export` (dry run) | |
| Approve the review | `wi accept add-csv-export` | say "accept" |
| Ask for changes | `wi reject add-csv-export "reason"` | say what to change |
| Release | `wi release add-csv-export --yes [--push]` | `/wi-release` |
| Where is everything | `wi status`, `wi status <slug>`, `wi config` | |

You can switch between the two at any point. State lives in the work item
document's front matter, so an agent picks up from whatever you did by hand and
vice versa.

## Human gates

`wi approve` and `wi accept` are the two gates. The skills forbid agents from
running either without your words in the conversation. That is an instruction,
not enforcement. To enforce it, add a `PreToolUse` hook that blocks Bash commands
matching `wi (approve|accept)`; you then run them yourself with `! wi approve <slug>`.

Pushing is off unless you pass `--push` or set `auto_push: true`. `wi` never
force-pushes, never rebases a pushed branch, and never deletes a branch whose
content is not on the base.

## Project configuration

Every key is optional. Put it in the project's `CLAUDE.md`; `wi config` shows the
resolved values.

```markdown
## Work Item Workflow

- work_items_root: docs
- work_item_path: <work_items_root>/<epic>/<type>-<slug>.md
- types: epic, story, bug, task
- branch_pattern: <type>/<slug>
- base_branch: main
- worktree: enabled                 # or disabled
- worktree_path: ../<repo>-worktrees/<type>-<slug>
- verify_commands:                  # default: detected from package.json, Makefile, pyproject, go.mod, Cargo.toml
  - npm test
  - npm run lint
- test_command: npm test            # what `wi verify --quick` runs
- review_mode: report               # report | pr
- changelog: CHANGELOG.md
- version_policy: semver            # semver | none
- version_files: package.json       # comma-separated; default detected
- tag_releases: true
- tag_pattern: v<version>
- auto_push: false                  # lets wi-auto push branches and releases
- tdd_agent: true                   # wi-build spawns test-engineer for each step's failing tests
- doc_template: .claude/templates/work-item.md
- epic_template: .claude/templates/epic.md
```

## How the document moves

`wi new` writes the document in the main checkout. `wi start` moves it onto the
new branch and commits it there, so the main checkout stays clean. During build,
the document is the one file allowed to be dirty; `wi sync` commits its progress.
`wi release` closes it out and promotes the changelog on the branch, then merges
the branch with `--no-ff` and tags that merge commit. Nothing is ever committed
directly to the base: the merge commit is the only commit `wi` adds there, so
`git log --first-parent main` reads as one line per work item.

Status: `planned → in-progress → staged → released`, with `changes-requested`
as the way back from review.

Epic documents stay in the main checkout. `wi` updates their child table's
Status column by slug and never commits them; commit epics yourself.

## Known limits

- `package-lock.json`'s own version field is not bumped; the next `npm install`
  corrects it. Do not list it in `version_files`: `wi` edits only the first
  `"version"` key in a file.
- Config values are read line by line; a ` #` inside a verify command is taken as
  a comment.
- `review_mode: pr` needs the `gh` CLI. The close-out commit is pushed to the
  pull request just before merging; if the host dismisses approvals on new
  commits, re-approve and re-run `wi release`.
- The document does not record the merge commit's hash (it is written before the
  merge exists). `git rev-list -n1 <tag>` or `git log --merges --grep <slug>`
  finds it.
