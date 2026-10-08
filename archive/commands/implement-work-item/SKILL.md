---
name: implement-work-item
description: Phase 2 of the work item workflow. Use when an approved work item document exists and it is time to write the code. Sets up the worktree and branch from project conventions, then executes the documented implementation plan step by step, writing the documented tests. Trigger on "implement this", "start on this story", "build the work item", "let's code this up", or approval of a plan produced by plan-work-item.
---

# Implement a work item

Phase 2 of a four-phase workflow: **Plan → Implement → Stage → Release**.

The work item document is the specification. This phase executes it — it does
not redesign it. When the code disagrees with the document, the document is
updated deliberately and the change is logged, never worked around silently.

## Project configuration

Read `CLAUDE.md` at the repository root before doing anything, plus any nested
`CLAUDE.md` closer to the code being changed. Project config overrides every
default in this skill. Look for a `## Work Item Workflow` section.

When a key is absent, **use the default silently** — do not ask, do not
announce the fallback.

| Key | Default |
|---|---|
| `work_items_root` | `docs` |
| `work_item_path` | `<work_items_root>/<epic>/<type>-<slug>.md` |
| `branch_pattern` | `<type>/<slug>` |
| `base_branch` | the repository's default branch |
| `worktree` | `enabled` |
| `worktree_path` | `../<repo>-worktrees/<type>-<slug>` |
| `verify_commands` | detected from the project (see step 5) |
| `commit_style` | Conventional Commits |
| `commit_granularity` | one commit per implementation-plan step |
| `requirement_id_prefix` | `R` (tests `T`, acceptance criteria `AC`) |

Placeholders: `<repo>` is the repository directory name, `<type>` the work item
type, `<slug>` the kebab-case title.

Project `CLAUDE.md` also carries the things this skill deliberately does not
guess: code style, architectural rules, directory layout, and anything the
project forbids. Follow it over any general habit.

## Steps

### 1. Load the document

Locate the work item document. If the user named it, use that path; otherwise
search `work_items_root` recursively for a document whose front matter `slug`
or title matches what the user described. If more than one matches, ask.

Read the whole document. If it has no requirements, no test plan, or no
implementation plan, stop and send it back to `plan-work-item` rather than
improvising the missing parts.

Check the front matter `status`:

- `planned` — the plan must also carry an `approved` date. If it is empty, the
  plan has not been approved; stop and ask for approval rather than assuming it.
- `in-progress` — this is a resumption. Pick up at the first unticked
  implementation-plan step and skip to step 4.
- `changes-requested` — review asked for changes. Read the requested changes
  from the progress log, set the status back to `in-progress`, and work them as
  implementation steps. The branch and worktree already exist, so skip to step 4.
- `staged` or `released` — stop; this item has moved past implementation.

### 2. Check the starting state

From the repository root:

- Confirm this is a git repository. If it is not, stop and say so — this
  workflow's Implement, Stage, and Release phases all assume version control.
- The working tree must be clean. If it is not, stop and report what is
  uncommitted; do not stash or discard the user's work.
- If a remote is configured, fetch and make sure the base branch is current.
  If there is no remote, work locally and note it; every later push step is
  then skipped rather than failed.

### 3. Create the worktree and branch

Branch name comes from `branch_pattern` and the document's front matter.

When `worktree` is enabled (the default):

- Create the worktree at `worktree_path` with a new branch off the current
  base branch.
- Create the parent directory for the worktree root if it does not exist.
- If the target path already exists, stop and report; do not reuse or clobber it.
- Do all subsequent work inside the worktree.
- After creating it, run the project's dependency install step if the worktree
  needs its own (node_modules, virtualenv, and similar are not shared).

When `worktree` is disabled, create the branch off the base branch in place.

Write the branch name into the document's front matter `branch`, the worktree
path into `worktree_path` (leave it empty when no worktree was used), set
`status: in-progress`, and append a progress log line. If the item belongs to an
epic, update its row in the epic document to `in-progress`.

### 4. Execute the implementation plan

Work the plan in order, one step at a time.

For each step:

1. Make the change the step describes, touching the files it names.
2. Write or update the tests from the test plan that cover the behavior this
   step introduces.
3. Run the relevant tests. Get them passing before moving on.
4. Commit, using `commit_style`. Reference the work item slug in the message
   body so the history is traceable back to the document.

Do not batch the whole plan into one commit unless `commit_granularity` says so.

**Keep the document current as you go.** Tick each implementation-plan step's
checkbox as it lands, and
append a progress log line at each meaningful milestone — not a line per file,
but enough that someone reading the document tomorrow knows where things stand.

### 5. Verify against the document

Run the project's full verification. Use `verify_commands` when configured;
otherwise detect them from the project's own tooling — the test, lint, type
check, and build scripts defined in its manifest, task runner, or CI config.
Run what exists; skip what does not.

Then check the work against the document itself:

- Every requirement in the document has the behavior it describes.
- Every test in the test plan exists, runs, and passes.
- Every acceptance criterion would pass a manual check.
- Nothing listed under "Must not change" changed.

Report any gap rather than quietly declaring completion.

### 6. Handle plan drift

When the plan turns out to be wrong — a requirement is infeasible, a step's
approach does not survive contact with the code, or a requirement is missing:

1. Stop coding.
2. Say plainly what the document says, what the code demands, and what you
   propose.
3. For a small correction (a step's approach, a file that moved), update the
   document, log the change, and continue.
4. For anything that changes scope, requirements, or the test plan, get the
   user's agreement before continuing.

Never satisfy a test by weakening it, and never delete a documented test
because it is inconvenient.

### 7. Report and hand off

Summarize:

- branch and worktree path
- commits made, in order
- requirement-by-requirement status
- verification results, including anything skipped and why
- anything that drifted from the plan

Leave the branch committed and the document updated. Hand off to
`stage-work-item`. Do not push, open a pull request, bump a version, or touch
the changelog — those belong to the Stage phase.

## Guardrails

- Never work directly on the base branch.
- Never force-push, rewrite published history, or `git checkout --` over
  uncommitted work that is not yours.
- Never commit secrets, credentials, or `.env` files; check before staging
  anything that looks like configuration.
- Never mark an implementation step done while its tests fail.
- Never expand scope beyond the document. Noticed-but-unrelated problems get
  written into the document's risks section or proposed as a new work item —
  not fixed in this branch.
