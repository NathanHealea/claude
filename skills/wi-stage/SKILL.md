---
name: wi-stage
description: Phase 3 of the wi work item workflow. Use when a work item's implementation is done and it needs readying for review. Syncs with the base branch, fans the diff out to reviewer subagents (code-reviewer, security-auditor, a11y-privacy-auditor, test-engineer), verifies and fixes their findings, writes the changelog entry, and runs `wi stage` to bump the version and mark it staged. Trigger on "stage this", "ready this for review", "prep the PR", "get this reviewed", or /wi-stage.
---

# Stage a work item

Phase 3 of **Plan → Build → Stage → Release**. Everything that must be true at
merge time is made true here, including the changelog entry and version bump —
they belong to the reviewed change. This phase never merges.

Work inside the item's worktree (`wi status <slug>` shows `worktree_path`).

## 1. Sync

```bash
wi sync <slug>
```

Commits the document's progress, brings the branch current with the base
(rebase before the first push, merge after), and runs full verification. If it
stops on a conflict or a failure, report it and stop. A stale or red branch is
not ready for review.

## 2. Fan out the review

Get the diff range: `git diff <base>...HEAD` where `<base>` is what `wi config`
prints (use `origin/<base>` when a remote exists). Spawn these subagents **in a
single message so they run in parallel**. Give each the same brief: worktree
path, document path, the diff range, and the instruction to review only what the
diff changed or directly affects.

- `code-reviewer` — correctness against the document, conventions, design.
- `security-auditor` — untrusted input, auth, secrets, dependencies.
- `a11y-privacy-auditor` — WCAG 2.1 AA and FERPA. It reports "no surface" when
  the diff renders nothing and touches no records about people; that is a
  valid result.

After those three return, spawn `test-engineer` in **audit** mode. It runs
mutation checks that temporarily edit source files, so it must not overlap with
reviewers reading the same files.

Reviewers find candidates. They do not get the last word.

## 3. Verify every finding

For each finding, open the file at the cited line yourself and decide: is it
real, is it in this diff's scope, is it already handled (by a caller, a type, a
framework default, a deliberate suppression), and can you state the inputs that
make it fail? Drop anything you cannot demonstrate, anything a configured linter
or type checker catches, and style preferences the project has not written down.
A short list of real findings beats a long one the user has to triage.

## 4. Fix what is clearly wrong

Fix verified HIGH and MED findings that are inside the work item's scope, one at
a time, smallest change, each with its own commit in the project's convention
(no attribution trailers). Add or adjust a test when the finding was a missed
behavior. Run `wi verify --quick` after each.

Do not fix: anything that changes requirements or scope, anything outside the
diff, or anything that is a judgment call. Those go in the review notes for the
human.

If you fixed anything, run one more review cycle limited to the reviewers whose
findings you fixed, against only the new commits. Two cycles total, then stop
and hand whatever remains to the human.

## 5. Changelog entry

If the project has a changelog (`wi config` shows it), add the entry under
`Unreleased` in the section matching the work: Added for a story, Fixed for a
bug, Changed or Removed when that fits better. Write for someone reading release
notes: what changed from the user's point of view, not which function moved.
Leave the file uncommitted; `wi stage` commits it with the version bump.

## 6. Stage

```bash
wi stage <slug> [--push] [--breaking]
```

It re-checks that the branch is current, re-runs verification, refuses without a
changelog entry when a changelog exists, bumps the version by the item's type
(story minor, bug/task patch, `--breaking` major), commits changelog + version +
document as one commit, and marks the item staged.

Pass `--breaking` only when consumers must change something to upgrade — then say
so in the changelog entry and the review notes.

Pass `--push` only when the user asked for it in this conversation, or when
`wi config` shows `auto_push: true`. Pushing publishes the branch.

**Pull requests.** When `wi config` shows `review_mode: pr`, write the PR body to
a temp file — summary, link to the work item document, requirement checklist,
verification results, review notes, what to look at hardest — and ask before
running `wi pr <slug> --body-file <file> [--draft]`. Opening a PR is publishing;
it needs the user's go-ahead unless `auto_push: true`. Never merge it here.

## 7. Report

Then run `wi release <slug>` with **no** `--yes`. It is a dry run: it changes
nothing and prints the merge plan. Include its output so the user's approval of
the review is also an informed approval of the release.

Report, in this order and tersely:

- verification: each command, pass or fail
- requirements: R-by-R, where in the diff
- review: fixed findings (one line each), then findings left for the reviewer
  with `file:line`, severity, and failure scenario
- version and changelog, or why skipped
- where the review lives: PR link, pushed branch, or local branch
- the release dry-run plan
- what the user needs to say: "accept" (→ `wi-release`) or the changes they want
  (→ `wi reject`, back to `wi-build`)

If the diff is more than a few hundred meaningful lines or mixes unrelated
concerns, say so and suggest how a future plan could split it.

## Guardrails

- Never merge, tag, or deploy here.
- Never stage with failing verification, and never soften a test to pass it.
- Never force-push. `wi` never does; do not do it by hand.
- Never run `wi accept` yourself. It is the human's review approval.
- An empty findings list on a substantial diff is itself suspicious — say what
  each reviewer actually checked.
