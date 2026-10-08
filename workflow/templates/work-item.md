---
type: story          # story | bug | task
epic: <epic-slug>    # removed by `wi new` when there is no parent epic
slug: <slug>
status: planned      # planned | in-progress | changes-requested | staged | released
branch: <branch>
worktree_path:       # set by `wi start`
created: <YYYY-MM-DD>
approved:            # set by `wi approve`
commit_type:         # optional override for the merge commit type (default: story=feat, bug=fix, task=chore)
version:             # set by `wi stage`
review_approved:     # set by `wi accept`
pr:                  # set by `wi pr`
tag:                 # set by `wi release`; the tag sits on the merge commit
---

# <Title>

## Summary

One paragraph. What this work is and why it is worth doing. `wi release` uses
this paragraph as the body of the merge commit.

## Context

Current behavior, the problem or opportunity, where it lives in the codebase,
and links to related work items. For a bug: how to reproduce it, and what the
observed vs. expected behavior is.

## Scope

**In scope**

- <thing this work will do>

**Out of scope**

- <thing a reader might reasonably assume is included but is not>

## Requirements

Atomic, testable, stated as observable behavior.

- **R1** — <requirement>
- **R2** — <requirement>

## Acceptance criteria

- **AC1** (R1) — Given <state>, when <action>, then <observable outcome>.
- **AC2** (R2) — Given <state>, when <action>, then <observable outcome>.

## Test plan

| ID | Covers | Test | File | Asserts |
|----|--------|------|------|---------|
| T1 | R1 | `<test name>` | `<path>` | <what it asserts> |
| T2 | R1 | `<test name>` | `<path>` | <failure / edge case> |
| T3 | R2 | `<test name>` | `<path>` | <what it asserts> |

**Not unit testable:** <requirement ID and how it will be verified instead, or "None.">

## Implementation plan

Each step: one reviewable change, the files it touches, and the tests that prove it.
Riskiest step first when the order allows.

1. [ ] <step> — touches `<files>` — tests T1, T2
2. [ ] <step> — touches `<files>` — tests T3
3. [ ] <step> — touches `<files>` — tests none (wiring only)

**Must not change:** <public API, schema, config contract, or "Nothing.">

**High-risk steps:** <step numbers touching auth, data migrations, deletion, secrets, or anything `git revert` cannot undo — or "None.">

## Risks and open questions

- <risk, unknown, or decision needed>

## Progress log

- <YYYY-MM-DD> — Planned.
