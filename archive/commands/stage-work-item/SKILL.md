---
name: stage-work-item
description: Phase 3 of the work item workflow. Use when a work item has been implemented and needs to be readied for review and merge. Verifies the build, self-reviews the diff against the work item document, updates the version and changelog, pushes the branch, and prepares the review - opening a pull request only when the project defines one. Trigger on "stage this", "ready this for review", "prep the PR", "get this reviewed", or completion of implement-work-item.
---

# Stage a work item

Phase 3 of a four-phase workflow: **Plan → Implement → Stage → Release**.

Staging turns a finished branch into something someone can review and merge
with confidence. Everything that must be true at merge time is made true here —
including the version bump and changelog entry, which belong to the reviewed
change, not to the merge.

**This phase does not merge.** Merging is Release.

## Project configuration

Read `CLAUDE.md` at the repository root before doing anything. Project config
overrides every default in this skill. Look for a `## Work Item Workflow`
section.

When a key is absent, **use the default silently** — do not ask, do not
announce the fallback.

| Key | Default |
|---|---|
| `work_items_root` | `docs` |
| `base_branch` | the repository's default branch |
| `verify_commands` | detected from the project |
| `review_mode` | `report` (see "Review process") |
| `pr_location` | none — no pull request is opened |
| `pr_template` | the repository's own PR template if one exists |
| `changelog` | `CHANGELOG.md` if present in the repository, else none |
| `changelog_format` | Keep a Changelog, under an `Unreleased` heading |
| `version_files` | detected from the project manifest |
| `version_policy` | semver, inferred from the work item type |
| `commit_style` | Conventional Commits |
| `worktree` | `enabled` |
| `worktree_path` | the document's front matter, else `../<repo>-worktrees/<type>-<slug>` |
| `requirement_id_prefix` | `R` (tests `T`, acceptance criteria `AC`) |

Work in the worktree the Implement phase created, when the document records
one. Placeholders: `<repo>` is the repository directory name, `<type>` the work
item type, `<slug>` the kebab-case title.

## Steps

### 1. Load the document and the diff

Read the work item document. Read the full diff of the branch against the base
branch — the whole diff, not a summary of it.

Confirm the working tree is clean and the branch is current with the base
branch. Resolve conflicts before anything else; a review of a stale branch
wastes the reviewer's time.

How to bring it current depends on whether the branch has been pushed. Before
the first push, rebase onto the base branch. After it has been pushed, merge the
base branch in instead — rebasing would require a force-push. If the history
genuinely needs rewriting after a push, say why and get the user's agreement
before force-pushing with lease.

### 2. Verify

Run the project's full verification: tests, lint, type check, build, and
whatever else the project defines. Use `verify_commands` when configured,
otherwise detect them from the project's manifest, task runner, or CI config.
Run what exists; skip what does not, and say which checks were unavailable.

**If anything fails, stop here.** Report the failures and do not continue.
A branch with a failing build is not ready for review, and pushing it anyway
makes the reviewer do the triage.

### 3. Self-review against the document

Go through the diff deliberately. This is the step that catches what tests do
not.

Against the document:

- Each requirement — is it implemented, and does the diff show where?
- Each test in the test plan — does it exist, does it actually assert the thing,
  and does it fail when the behavior is broken?
- Each acceptance criterion — would it pass a manual check?
- "Must not change" — did anything in that list change?

Against the diff itself:

- Debug output, commented-out code, `TODO`s added in passing, stray files.
- Secrets, credentials, tokens, internal hostnames, real user data in fixtures.
- Changes outside the work item's scope. Unrelated fixes that snuck in should
  be split out or called out explicitly.
- Error handling and edge cases the tests do not reach.
- Anything a reviewer would ask about — answer it in the review notes before
  they have to ask.

Record what you find. Fix what is clearly wrong; raise what is a judgment call.

### 4. Version and changelog

These land **in the branch, before review**, so the reviewer sees them and the
merge carries them.

**Changelog** — if a changelog file exists, add an entry for this work item.
Under the default `changelog_format` that means an entry beneath the
`Unreleased` heading in the section matching the work item type (Added / Fixed /
Changed / Removed); under any other format, follow the file's existing
structure. Write it for a human reading release notes, not a commit log: what
changed from the user's point of view, not which function moved.

**Version** — if the project defines `version_files` or the version is
discoverable in its manifest, bump it according to `version_policy`. Under the
default semver policy: breaking change → major, `story` → minor, `bug`/`task` →
patch, and any project-defined type → patch unless `CLAUDE.md` maps it. Under
any other policy, follow the scheme `CLAUDE.md` describes; if it names a policy
but does not describe it, ask. When the project releases on a train or bumps at
release time instead, say so in `CLAUDE.md` and this step is skipped.

If neither a changelog nor a version file exists, skip this step without asking,
but record the skip in the review notes.

Commit these as their own commit, using `commit_style`.

### 5. Push the branch

Push the branch to the remote, setting upstream. If the repository has no
remote, skip this and say so — the review then happens against the local branch,
and `review_mode: pr` is not usable. Never force-push a branch that others may
have based work on; if history needs rewriting, say so and get agreement first.

### 6. Prepare the review

See "Review process" below and follow the configured `review_mode`.

### 7. Update the document and report

Set `status: staged` in the document's front matter and append a progress log
line with the date, the verification result, and the review location if there
is one. If the item belongs to an epic, update its row in the epic document.

If the review comes back asking for changes, set `status: changes-requested`,
record what was asked for in the progress log, and hand back to
`implement-work-item`.

Report:

- verification results, command by command
- requirement-by-requirement confirmation
- findings from the self-review, separated into *fixed* and *for the reviewer*
- version and changelog changes, or why they were skipped
- where the review is (PR link, review packet path, or "self-review only")
- what is left before Release

## Review process

Not every project uses pull requests, so `review_mode` selects how the work is
put in front of a reviewer. Set it in `CLAUDE.md`.

**`report`** *(default)* — No pull request. Produce a review report in the
conversation: the requirement-to-change mapping, the self-review findings, the
verification output, and a suggested review order through the diff (start with
the interface or schema change, then the logic, then the tests). The branch is
pushed so anyone can check it out. Use this for solo work and for repositories
with no review host.

**`pr`** — Open a pull request at `pr_location`. Title from the work item, body
from the repository's PR template when one exists, otherwise: summary, link to
the work item document, requirement checklist, test plan results, self-review
notes, and anything you want the reviewer to look at hardest. Mark it draft if
anything is still open. Opening the PR is a publishing action — confirm with
the user before opening it, and never merge it here.

**`patch`** — Produce a reviewable patch or diff file for projects that review
by email or attachment, written beside the work item document, together with
the same review notes as `report`.

**`none`** — Verify, self-review, push, and stop. No review artifact.

Whichever mode is in use, the honest self-review in step 3 is the substance;
the mode only decides where it gets delivered. If the change is large enough
that a reviewer will struggle — roughly, more than a few hundred meaningful
lines or several unrelated concerns in one diff — say so and suggest how it
could be split, even though the work is already done. That feedback improves
the next plan.

## Guardrails

- Never merge, tag, or deploy in this phase.
- Never push with a failing verification.
- Never force-push a shared branch.
- Never open or update a pull request without the user's go-ahead.
- Never soften a test to make the build pass.
- Do not report a clean review you did not actually perform — an empty findings
  list on a substantial diff is a finding in itself.
