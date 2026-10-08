# Reporting

## Severity

Severity is about consequence, not effort to fix.

**HIGH** — it will hurt someone or break in production. A wrong result users act on. Data loss. An unauthenticated path to a record. Student data leaving where it lives. An interface a keyboard or screen-reader user cannot complete at all. A hardcoded credential in a tracked file.

**MED** — it will break under conditions that occur in normal use. The empty-collection case. The second concurrent request. The page at 320px. A convention the project wrote down and this code ignores. An accessibility barrier a user can work around but should not have to.

**LOW** — real, verified, but the consequence is small or the trigger is rare. A confusing error message. A comment that no longer matches the code. An `alt` attribute that is present but unhelpful.

Two rules: a finding you could not write a failure scenario for is not a finding at any severity, and there is no severity below LOW. Preferences go in the "Preferences" list, not the findings.

## Finding format

Four parts, always, in this order:

```
SEV   path/to/file.ext:LINE — one-line statement of what is wrong
      What actually goes wrong: the inputs or state, and the resulting behavior.
      Why it is wrong: the rule, standard, or semantics it violates — cited.
      Fix: the direction, in one line. Not a patch.
```

The citation is what makes a finding arguable rather than assertable. Name the source:

- Conventions — quote the line from the CLAUDE.md, lint config, or contributing guide.
- Accessibility — name the success criterion by number and title: "WCAG 2.1 SC 1.4.3 Contrast (Minimum), Level AA".
- Privacy — name the rule: "34 CFR 99.3, student ID is not directory information".
- Security — name the class: "CWE-89, SQL injection" or "untrusted input reaches `eval`".
- Correctness — the language semantics or the API contract, with the line that proves it.

If you cannot name a source, you are reporting a preference. Say so and move it.

## Report shape

```
Reviewed: <target> (<n> files, <n> lines) — <stack>
Standard: <sources used, and whether linters were run and what they said>
Lenses:   <lenses run>  (<lens>: <why skipped>)

<findings, most severe first>

Preferences (not findings):
  - <thing you would have done differently, one line each>

Excluded: <generated/vendored paths>
Not covered: <files or lenses the target's size forced out of scope>
Also noticed (outside the target): <serious pre-existing issue, one line>
```

`Not covered` is not an apology, it is a result. A reader who does not know where the review stopped will assume it stopped nowhere.

## Ordering

Most severe first, and within a severity, group by file so the user can work through one file at a time. Do not number findings across the whole report — it invites "fix 3 and 7" and then nobody can tell which was which after a re-review.

## Subagent output contract

When a subagent does part of the review, require exactly this per finding, and reject prose impressions:

```
file: src/api/roster.ts
line: 47
severity: MED
claim: findAll() returns undefined for a course with no enrolments
scenario: GET /courses/8813/roster where course 8813 has zero enrolments;
          line 47 reads .length on undefined and throws, 500 to the caller
basis: findAll() at src/db/enrolments.ts:22 returns the raw driver result,
       which is undefined rather than [] when no rows match
fix: default to [] in findAll()
confidence: high | medium | low
```

`basis` must point at code the agent actually read, with its location. An agent that cannot fill in `basis` has found a suspicion, not a finding, and it returns it as `confidence: low` or not at all.

Subagent findings are candidates. The main review re-opens each cited line and decides — a subagent's `confidence: high` is not a verification, because the agent that formed the suspicion is the worst judge of it.

## Length

A report the user reads end to end beats a complete one they skim. Five verified findings is a good review. Twenty means either the code is genuinely bad or the verification step was skipped — check which before printing it.
