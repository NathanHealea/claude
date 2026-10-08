---
type: epic
slug: <epic-slug>
status: planned      # planned | in-progress | staged | released
created: <YYYY-MM-DD>
---

# <Epic title>

## Summary

One paragraph. The outcome this epic delivers and why it is worth doing.

## Context

Where this sits in the product and the codebase, what exists today, and what
prompted it.

## Scope

**In scope**

- <area of work>

**Out of scope**

- <area a reader might assume is included but is not>

## Requirements

Epic-level requirements. Each child work item will inherit or refine one or more.

- **R1** — <requirement>
- **R2** — <requirement>

## Acceptance criteria

What "this epic is done" means, checked at the epic level.

- **AC1** (R1) — Given <state>, when <action>, then <observable outcome>.

## Child work items

Each child gets its own `plan-work-item` pass when it is picked up.

Status uses the same vocabulary as a work item: `planned`, `in-progress`,
`changes-requested`, `staged`, `released`. Each phase updates the child's row
in this table when it updates the child's own document.

| # | Type | Title | Covers | Depends on | Status |
|---|------|-------|--------|-----------|--------|
| 1 | story | <title> | R1 | — | planned |
| 2 | task | <title> | R1 | 1 | planned |
| 3 | story | <title> | R2 | 1 | planned |

**Independently shippable:** <which children can ship alone, and which cannot.>

## Risks and open questions

- <risk, unknown, or decision needed>

## Progress log

- <YYYY-MM-DD> — Planned.
