---
name: plan-work-item
description: Phase 1 of the work item workflow. Use when starting any new body of work - a feature, bug fix, enhancement, refactor, chore, or a large epic to break down. Creates a work item document containing the description, requirements, unit test plan, and implementation plan, then stops for approval before any code is written. Trigger on "plan this", "new story", "new bug", "new task", "write up this work", "break down this epic", or "create a work item".
---

# Plan a work item

Phase 1 of a four-phase workflow: **Plan → Implement → Stage → Release**.

The output of this phase is a single markdown document. That document is the
contract for every later phase: `implement-work-item` builds from it,
`stage-work-item` reviews against it, `release-work-item` closes it out.
Write it so a competent engineer who has never seen the conversation could
execute it.

**Write no code in this phase.** Reading the codebase is expected and
encouraged. Changing it is not.

## Project configuration

Read `CLAUDE.md` at the repository root before doing anything, plus any
nested `CLAUDE.md` closer to the code being changed. Project config overrides
every default in this skill. Look for a `## Work Item Workflow` section.

When a key is absent, **use the default silently** — do not ask, do not
announce the fallback.

| Key | Default |
|---|---|
| `work_items_root` | `docs` |
| `work_item_path` | `<work_items_root>/<epic>/<type>-<slug>.md` |
| `types` | `epic`, `story`, `bug`, `task` |
| `slug` | kebab-case from the title, 2–5 words, no type prefix |
| `branch_pattern` | `<type>/<slug>` |
| `doc_template` | `templates/work-item.md` in this skill |
| `epic_template` | `templates/epic.md` in this skill |
| `requirement_id_prefix` | `R` (tests `T`, acceptance criteria `AC`) |

Placeholders: `<repo>` is the repository directory name, `<epic>` the epic
folder, `<type>` the work item type, `<slug>` the kebab-case title.

## Steps

### 1. Classify the work

Decide the type from what the user describes. Ask only if genuinely ambiguous.

- **epic** — a large body of work that will take more than one branch, or that
  naturally decomposes into several independently shippable pieces.
- **story** — new or changed behavior a user can observe.
- **bug** — existing behavior that is wrong. The requirements describe the
  correct behavior; the test plan must include a regression test that fails
  on the current code.
- **task** — necessary work with no directly observable behavior change:
  refactors, dependency bumps, tooling, infrastructure, docs.

If `types` in `CLAUDE.md` defines types beyond these four, classify by the
project's own definitions of them.

If the work is an epic, follow "Planning an epic" below instead of steps 2–6.

### 2. Establish the file path

Derive `<slug>` from the title. Resolve `<epic>`:

- If this item belongs to an existing epic, use that epic's folder.
- If the user names a new epic, create the folder.
- If there is no epic, drop the folder segment: `<work_items_root>/<type>-<slug>.md`.

Check the path is free. If a document already exists there, stop and ask
whether to revise it rather than overwriting it.

### 3. Understand before you specify

Read the relevant code, existing tests, and any sibling work item documents in
the same epic folder. Requirements written without reading the code are guesses.

Note specifically: the test framework and runner in use, existing test file
layout and naming conventions, and how similar behavior is already implemented.
The test plan must match the project's actual conventions, not generic ones.

If the project has no test framework at all, say so in the test plan and state
how each requirement will be verified instead. Do not invent a framework, and
do not propose introducing one as part of this work item — that is its own task.

### 4. Draft the document

Use `doc_template`. Every section is required; a section with nothing
to say gets an explicit "None." rather than being deleted.

Quality bar for each section:

**Requirements** — Numbered `R1`, `R2`, … Each one atomic, testable, and
stated as observable behavior, not implementation. "R3 — Expired tokens are
rejected with a 401" is a requirement. "R3 — Add a check in `validate()`" is
not; that belongs in the implementation plan.

**Acceptance criteria** — Given/When/Then, each tagged with the requirement it
proves. These are what a reviewer checks by hand.

**Test plan** — At least one unit test per requirement, in the table format the
template gives. Name the test using the project's existing convention, name the
file it belongs in, and state what it asserts. Include failure and edge cases,
not only the happy path. For a bug, the first row is the regression test.
If a requirement cannot be unit tested, say so explicitly and state how it will
be verified instead (integration test, manual check, monitoring).

**Implementation plan** — Ordered, numbered steps, written as a checklist so the
Implement phase can tick them off. Each step names the files it touches and is
small enough to review alone. Order steps so the work is
coherent at each stop: schema before the code that reads it, tests alongside or
before the code they cover if the project works that way. Call out anything
that must not change (public API surface, migrations, config contracts).

**Risks and open questions** — Real ones. Unknowns you could not resolve from
the code, decisions the user needs to make, and anything that could make the
estimate wrong. An empty list here on non-trivial work usually means the
codebase was not read closely enough.

### 5. Write the file and show it

Create the document at the resolved path, filling `branch` in the front matter
from `branch_pattern` and leaving `approved` empty. Then summarize in chat:

- the path written
- the type, epic, and proposed branch name
- the requirement count and test count
- any open questions that need an answer before implementation

### 6. Stop

**Do not begin implementation.** End the turn with the document written and the
open questions raised. Wait for explicit approval.

When the user approves, record it in the document — set `approved` in the front
matter to today's date and append a progress log line — then hand off to
`implement-work-item` and name the document path, so the next phase starts from
the file rather than from memory of this conversation.

## Planning an epic

An epic document lives at `<work_items_root>/<epic>/epic-<slug>.md`, where
`<slug>` matches the folder name. Use `epic_template`.

An epic replaces the test plan and implementation plan with a **child work
items** checklist. For each proposed child, give the type, the working title,
a one-line description, and its dependencies on other children. Do not write
the children's documents yet — each child gets its own `plan-work-item` pass
when it is picked up, so it can be planned against the code as it exists then.

Sequence the children so that each is independently shippable where possible,
and mark the ones that are not.

After writing the epic document, stop the same way: summarize and wait.

## Revising an existing document

If asked to change a plan that already exists, edit the document in place and
append a line to its **Progress log** saying what changed and why. Do not
silently drop requirements — strike them through or move them to "Out of scope"
with a reason, so the history stays readable.

## Guardrails

- No code changes, no branches, no commits in this phase.
- Do not overwrite an existing work item document without asking.
- Do not invent framework or test conventions; read them from the project.
- Do not pad the requirement list. Five real requirements beat fifteen
  restatements of the same one.
- Do not proceed to implementation without explicit approval.
