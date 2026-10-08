---
name: wi-plan
description: Phase 1 of the wi work item workflow. Use when starting any new body of work - a feature, bug fix, enhancement, refactor, chore, or an epic to break down. Writes a work item document (requirements, acceptance criteria, test plan, implementation plan) with `wi new`, then stops for approval before any code is written. Trigger on "plan this", "new story", "new bug", "new task", "write up this work", "break down this epic", "create a work item", or /wi-plan.
---

# Plan a work item

Phase 1 of **Plan → Build → Stage → Release**. Mechanics run through the `wi`
CLI so a human following the workflow by hand runs the same commands you do.
Run `wi --help` once if you have not seen it this session.

The document this phase writes is the contract for every later phase. Write it
so an agent with no memory of this conversation could build, test, and review
from it alone — in autonomous mode, that is exactly what happens.

**Write no code in this phase.** Read the codebase freely; change nothing except
the work item document.

## 1. Load configuration

Run `wi config`. It reads the `## Work Item Workflow` section of the repository's
`CLAUDE.md` and prints every resolved value, defaults included. Use what it
prints; do not re-derive defaults. Also read the project `CLAUDE.md` and any
nested `CLAUDE.md` near the code being changed — they carry the conventions
`wi` does not: code style, architecture rules, what is forbidden.

## 2. Make sure you know what is being asked

If the request is underspecified — no clear user, no clear outcome, or you
notice yourself inventing requirements — interview before writing anything.
Ask **one question at a time**, each with your best guess attached so the user
can answer "yes" instead of composing a reply:

```
Q: Who hits this — students on the portal, or advisors in the admin view?
My guess: advisors only, since the export button is admin-gated.
```

Stop interviewing when you could write every requirement without guessing.
Skip this step entirely when the request already says what, for whom, and why.

## 3. Classify and create the document

Pick the type: **epic** (spans several branches), **story** (new observable
behavior), **bug** (existing behavior is wrong), **task** (no observable change:
refactor, dependency bump, tooling, docs). If `wi config` lists extra types, use
the project's definitions.

```bash
wi new <type> "<Title>" [--epic <epic-slug>] [--slug <slug>]
```

`wi new` derives the slug, resolves the path, refuses to overwrite an existing
document, and fills the front matter. If it reports the path exists, stop and
ask whether to revise that document instead.

## 4. Understand before you specify

Read the relevant code, the existing tests, and sibling documents in the same
epic folder. Note the test framework and runner, test file layout and naming,
and how similar behavior is already built. The test plan must match the
project's real conventions. If there is no test framework, say so in the test
plan and state how each requirement will be verified instead; do not propose
adding one inside this work item.

## 5. Fill in the document

Every section is required. A section with nothing to say gets "None."

- **Requirements** — `R1`, `R2`, … atomic, testable, observable behavior. "R3 —
  Expired tokens are rejected with a 401" is a requirement; "R3 — add a check in
  `validate()`" is an implementation step.
- **Acceptance criteria** — Given/When/Then, each tagged with its requirement.
- **Test plan** — at least one test per requirement, named in the project's
  convention, with the file it lives in and what it asserts. Cover failure and
  edge cases. For a bug, T1 is the regression test that fails on current code.
- **Implementation plan** — numbered checklist steps in the exact form
  `N. [ ] <step> — touches \`<files>\` — tests T1, T2`. `wi next` and `wi tick`
  parse this form, so keep it. Each step is one reviewable commit. Order by
  dependency, riskiest first when dependencies allow, so a dead end shows up
  before the easy work is sunk. A step should touch roughly five files or fewer;
  split it if not.
- **Must not change** — public API, schema, config contracts.
- **High-risk steps** — any step touching authentication or authorization, data
  migrations, deletion, secrets, student or personnel records, or anything
  `git revert` cannot undo. Autonomous build stops before these for sign-off.
- **Risks and open questions** — real ones. An empty list on non-trivial work
  usually means the code was not read closely enough.

Accessibility (WCAG 2.1 AA) and student-data privacy (FERPA) are hard
constraints. If the work renders UI or touches records about people, add the
requirements and tests that prove it stays compliant, and flag any request that
would violate either.

## 6. Show it and stop

Summarize in chat: the path, type, epic, branch, requirement and test counts,
high-risk steps, and the open questions that block implementation.

**Do not begin implementation.** End the turn and wait.

When the user approves — in their own words, in a later turn — run:

```bash
wi approve <slug>
```

Never run `wi approve` on your own judgment. It is one of the two human gates.
Then hand off to `wi-build` (or let `wi-auto` continue) naming the document path.

## Epics

`wi new epic "<Title>" --slug <slug>` creates `<root>/<slug>/epic-<slug>.md`. An
epic replaces the test and implementation plans with the **Child work items**
table. Fill the Slug column with each child's exact future slug — `wi` updates
the Status column by matching it. Do not write children's documents yet; each
gets its own `wi-plan` pass when picked up. Epic documents stay in the main
checkout; `wi` updates their table in place and never commits them.

## Revising a plan

Edit the document in place and append a line with `wi log <slug> "<what changed and why>"`.
Strike through or move dropped requirements to Out of scope with a reason —
never silently delete them.
