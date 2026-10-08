---
type: epic
slug: <slug>
status: planned      # planned | in-progress | released
created: <YYYY-MM-DD>
approved:
---

# <Title>

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

- **AC1** (R1) — Given <state>, when <action>, then <observable outcome>.

## Child work items

Each child gets its own planning pass when it is picked up. `wi` updates the
Status column by matching the Slug column, so keep slugs exact.

| # | Type | Slug | Title | Covers | Depends on | Status |
|---|------|------|-------|--------|-----------|--------|
| 1 | story | <child-slug> | <title> | R1 | — | proposed |
| 2 | task | <child-slug> | <title> | R1 | 1 | proposed |

**Independently shippable:** <which children can ship alone, and which cannot.>

## Risks and open questions

- <risk, unknown, or decision needed>

## Progress log

- <YYYY-MM-DD> — Planned.
