---
type: story          # story | bug | task
epic: <epic-slug>    # omit this line when the item has no parent epic
slug: <slug>
status: planned      # planned | in-progress | changes-requested | staged | released
branch: <branch_pattern applied>
worktree_path:       # filled by Implement
created: <YYYY-MM-DD>
approved:            # date the plan was approved; empty until then
version:             # filled by Release
tag:                 # filled by Release
merge_commit:        # filled by Release
---

# <Title>

## Summary

One paragraph. What this work is and why it is worth doing.

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

1. [ ] <step> — touches `<files>`
2. [ ] <step> — touches `<files>`
3. [ ] <step> — touches `<files>`

**Must not change:** <public API, schema, config contract, or "Nothing.">

## Risks and open questions

- <risk, unknown, or decision needed>

## Progress log

- <YYYY-MM-DD> — Planned.
