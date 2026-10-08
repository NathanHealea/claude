---
name: wi-build
description: Phase 2 of the wi work item workflow. Use when an approved work item document exists and it is time to write the code, or when resuming one that is in progress or had changes requested. Creates the branch and worktree with `wi start`, then works the implementation plan step by step test-first, with the test-engineer subagent writing each step's failing tests. Trigger on "implement this", "build it", "start on this story", "pick this back up", "address the review", or /wi-build.
---

# Build a work item

Phase 2 of **Plan → Build → Stage → Release**. The document is the
specification; this phase executes it and does not redesign it. Every mechanical
step is a `wi` command a human could run by hand.

## 1. Start or resume

```bash
wi start <slug>
```

`wi start` does all the state checks and refuses with a reason when something
is off: plan not approved, uncommitted work in the main checkout, branch or
worktree already present, item past implementation. Report its message and stop
— do not work around it.

On success it prints `worktree:`, `doc:`, and `next:`. Do every later step
inside that worktree. On a fresh start it has already created the branch off the
current base, moved the document onto the branch, and committed it. On
`changes-requested` it flips the status back; read the progress log for what the
reviewer asked for and treat each request as an extra step, appended to the
implementation plan with `wi log` noting why.

A fresh worktree does not share installed dependencies. If the project needs an
install step (`npm ci`, `uv sync`, `bundle install`), run the one its lockfile
implies. Installing what the lockfile already pins is fine; adding a new
dependency is not — that needs the user's approval.

Run `wi verify` once before changing anything so you know the baseline. If it
already fails, stop and report: building on a red baseline hides which failures
are yours.

## 2. Work the plan, one step at a time

Loop until `wi next <slug>` prints `none`.

**a. Read the step.** `wi next <slug>` prints it: what to change, which files,
which test IDs. Pull those test rows from the test plan.

**b. Red — get failing tests.** If the step lists tests and `wi config` shows
`tdd_agent: true`, spawn the `test-engineer` subagent in **write** mode. Give it:
the document path, the step text, the test plan rows verbatim, and the worktree
path. It writes the tests without seeing your implementation, runs them, and
returns the files it wrote and the failure output. Separation is the point: tests
written by the implementer tend to test the implementation.

If `tdd_agent` is false, write the tests yourself first. Either way, run
`wi verify --quick` and confirm the new tests fail **for the stated reason** —
a test that fails on an import error proves nothing. A new test that passes
before any implementation is a finding: the behavior exists already or the test
asserts nothing. Stop and resolve it.

A step that lists no tests (wiring, config) skips red.

**c. Green — implement.** The smallest change that makes the tests pass, in the
files the step names. Match the surrounding code. No refactors, renames, or
dependency changes the step did not ask for. Follow the project's commenting
rules; by default, no comment unless it carries a why the code cannot.

**d. Verify.** `wi verify --quick` until green. Never weaken, skip, or delete a
test to get there. When a failure is not obvious, debug it properly:
reproduce it reliably, localize it (bisect the change, narrow the input), fix
the root cause, and keep the test that proves it. No retries, sleeps, or special
cases that hide a symptom.

**e. Commit.** Stage only the files this step touched — never `git add -A`, and
leave the work item document out (it is committed by `wi sync`). Use the commit
convention from the project `CLAUDE.md`, falling back to the global one:
`<type>(<scope>): <subject>`, imperative, under 72 characters, blank line, then a
body explaining why and naming the work item slug. Add no attribution trailers,
no tool or AI references, no session links.

**f. Record.** `wi tick <slug> <n>`. At meaningful milestones — not every step —
`wi log <slug> "<where things stand>"`.

## 3. Finish

Run the full `wi verify`. Then check the work against the document: every
requirement has its behavior, every planned test exists and passes, every
acceptance criterion would pass a manual check, nothing under "Must not change"
changed. Report any gap rather than declaring done.

Hand off to `wi-stage` with the document path. Do not push, bump versions, or
touch the changelog here.

## When to stop and ask

Stop, say plainly what the document says and what the code demands, and wait,
when:

- a step is listed under **High-risk steps** and the user has not signed off on
  it in this conversation
- the plan is wrong in a way that changes scope, requirements, or the test plan
  (a small correction — a file that moved, a step's approach — is fine: update
  the document, `wi log` the change, continue)
- a test cannot be made to pass after a real debugging attempt
- the change needs a new dependency, a schema change the plan did not list, or
  anything outside the document's scope

Noticed-but-unrelated problems go into the document's risks section or a
proposed new work item, never into this branch.
