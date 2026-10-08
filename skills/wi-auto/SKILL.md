---
name: wi-auto
description: Run the whole wi work item workflow with the fewest human interactions - plan, then after one plan approval build and stage autonomously, then stop for one review-and-release approval. Use when the user wants an agent to take a piece of work end to end, says "just do it", "take this end to end", "run it autonomously", "auto mode", or invokes /wi-auto. Resumes from wherever an existing work item stands.
---

# Autonomous work item

Runs **Plan → Build → Stage → Release** with exactly two human gates:

1. **Plan approval** — the user reads the work item document and says go.
2. **Review and release approval** — the user reads the stage report (review
   findings plus the release dry run) and says accept, or asks for changes.

Between the gates you do not check in. You stop early only for the conditions
listed under "Stop and ask". Each phase follows its own skill exactly; this skill
only sequences them and decides when to pause.

## Find where things stand

If the user named an existing item, run `wi status <slug>`; otherwise `wi status`
to see whether the request matches one already in flight. Enter at the matching
point:

| State | Enter at |
|---|---|
| no document | Plan |
| `planned`, not approved | Gate 1 — show the plan summary again and wait |
| `planned`, approved | Build |
| `in-progress` or `changes-requested` | Build (resume) |
| `staged` | Gate 2 — show the stage report again and wait |
| `released` | nothing to do; say so |

## Plan → Gate 1

Follow `wi-plan`. If the request is underspecified, interview first, one question
at a time — this is the cheapest moment to ask, because every later phase runs
without you. End the turn after the summary.

When the user approves, run `wi approve <slug>` and continue straight into Build
in the same turn. If they approve with edits, revise the document, log it, show
the diff of the plan, and then proceed — the edits were theirs.

## Build

Follow `wi-build` through every step without pausing between steps. Commit each
step. At the end, run the full `wi verify`.

## Stage → Gate 2

Follow `wi-stage`: sync, parallel reviewers, verify findings, fix in-scope
HIGH/MED findings (at most two review cycles), changelog entry, `wi stage`.
Pass `--push` only if `wi config` shows `auto_push: true`.

End the turn with the stage report, including the `wi release <slug>` dry-run
output, and one line saying what you need: "accept" to release, or the changes
to make.

## After Gate 2

- **Accept** → follow `wi-release`: `wi accept`, then `wi release <slug> --yes`,
  with `--push` only when `auto_push: true` or the user said to push.
- **Changes requested** → `wi reject <slug> "<summary>"`, then Build (resume)
  and Stage again, and return to Gate 2. Do not ask for plan approval again
  unless the requested changes alter requirements or scope.

## Stop and ask

Stop mid-run, report where things stand (`wi status <slug>`), and wait, when:

- the next step is listed under the document's **High-risk steps** and the user
  has not signed off on it in this conversation
- verification fails and a real debugging attempt did not find the root cause
- the plan is wrong in a way that changes requirements, scope, or the test plan
- the work needs a new dependency, an unplanned schema change, or access to a
  service the user has not named
- a reviewer finding is verified HIGH and cannot be fixed inside the item's scope
- any `wi` command refuses and the fix is not mechanical

When the user resolves it, re-invoke this skill; it resumes from the item's
recorded state.

## Never, even in autonomous mode

- run `wi approve` or `wi accept` without the user's explicit words in this
  conversation
- force-push, rewrite pushed history, or `git reset --hard`
- push, open a PR, or merge unless the gates and `auto_push` above allow it
- add attribution trailers or AI/tool references to commits, PRs, or changelogs
- copy student, HR, or personnel data into tests, fixtures, logs, or prompts
