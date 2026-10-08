---
name: review-code
description: Review existing code at a given target — a single file, a directory, or the whole project — against correctness, security, accessibility (WCAG 2.1 AA), privacy (FERPA), and the project's own written conventions. Use whenever the user asks for a code review of code that already exists rather than of a pending change — "review this file", "review src/api", "review the whole project", "audit this directory for accessibility", "is this code any good", "check this against our standards" — or invokes /review-code. Reports findings read-only and stops; applies fixes only on explicit approval. For reviewing an uncommitted diff, a branch, or a pull request, a diff-scoped reviewer is the better fit.
---

# Review code

Review code that already exists, at a target the user names.

The audience is the person who has to live with this code — usually the user, later, trying to change it without breaking something. A review earns its keep by finding the things that will actually bite: the bug that fires on the empty list, the form field no screen reader can name, the student ID written to a log. It loses its keep by listing everything a linter would have caught.

Three rules are absolute:

- **The review is read-only.** Reading, grepping, and running the project's own linters and tests are fine. Editing files is not, until the user has seen the findings and asked for fixes. A review that silently rewrites the code under inspection destroys the thing being reviewed.
- **Every finding is verified against the file before it is reported.** A finding you have not re-opened the file to confirm is a guess. See step 5 — this is the step that separates a useful review from noise, and it is the one most often skipped.
- **Never invent a standard.** Findings come from the project's written conventions, the language's real semantics, or a published standard you can name (a WCAG success criterion, a CWE). "I would have written it differently" is not a finding.

## 1. Resolve the target

The user gives a target and, optionally, one or more lenses:

```
/review-code src/api/handlers.ts
/review-code src/ui accessibility
/review-code . security privacy
/review-code src/ --since main
```

**Target** is a path: a file, a directory, or `.` for the whole project. With no target, use the current directory and say so in one line rather than asking.

**Lenses** narrow what the review looks for. With none given, run all five: correctness, security, accessibility, privacy, conventions. Named lenses replace the default set — `/review-code src/ui accessibility` reviews only for accessibility.

**`--since <ref>`** restricts the review to files under the target that changed since a git ref. Use it when the target is large and the user cares about recent work.

Run the survey from the repo:

```bash
bash <skill-dir>/scripts/survey.sh <target> [--since <ref>]
```

It reports the resolved path and kind, the file inventory by language, which standards files exist and where, whether tests and linters are configured, which directories are generated or vendored, and where the accessibility and privacy lenses have real surface area to review. Read its output before deciding anything else.

**Size the job before starting it.** The survey prints a total line count. Under roughly 1,500 lines, read everything yourself. Above that, the review has to be split — see step 4 — and above roughly 25,000 lines a whole-project review is not a single sitting. Say so, propose a split by module or by lens, and let the user pick. Do not start a review you cannot finish and then report on the third of it you got through as if it were the whole.

**Exclude generated and vendored code.** `node_modules/`, `vendor/`, `dist/`, `build/`, lockfiles, minified bundles, migrations, and anything a code generator emits. Reviewing them produces findings nobody can act on. The survey flags them; list what you excluded in the report so the user can overrule you.

## 2. Resolve the standard

A review measures code against something. Find out what, before reading any code.

Read every source the survey found. Precedence settles conflicts; it never excuses skipping a file.

1. **`CLAUDE.md` in the repo root**, plus `.claude/CLAUDE.md`, `CLAUDE.local.md`, and `AGENTS.md`. Also any `CLAUDE.md` in or above the target directory — a nested one is usually the most specific rule that applies.
2. **The global `~/.claude/CLAUDE.md`.** The user's standing rules across every repo. Open it whenever the project has nothing to say on a point. Its engineering rules are review criteria: smallest change that solves the problem, no new dependency without asking, errors handled explicitly and never swallowed, no comment unless it carries what the code cannot (a reason, a workaround, an invariant), never a comment that restates the code, no commented-out code, no hardcoded secrets or connection strings. Code that violates these is a finding.
3. **Machine-enforced config.** `.editorconfig`, ESLint, Prettier, Ruff, Flake8, Black, `tsconfig.json`, `.stylelintrc`, PHPCS. These are the project's conventions in executable form. If a linter is configured, run it rather than reviewing for what it already checks — then review for what it cannot.
4. **The surrounding code.** Where nothing is written down, the convention is what the neighbouring files actually do. Match it, even where you would have chosen otherwise.

Never state what a file says without having opened it. "The project has no accessibility rules" is a claim about files you read, not an inference from their absence in a directory listing.

Say in the report which sources you used. If the project and the global file genuinely conflict, the project wins and one line notes it — but conflict is narrower than it looks. A project that dictates a naming convention has said nothing about error handling or secrets, so the global rules on those still bind.

## 3. Pick the lenses that have surface area

Five lenses, each with its own reference file. Load a lens's reference only when you are running it.

- **Correctness** — bugs that will fire in practice. `references/lenses.md`.
- **Security** — untrusted input reaching somewhere it should not. `references/lenses.md`.
- **Accessibility** — WCAG 2.1 Level AA, a hard constraint in this user's work. `references/accessibility.md`.
- **Privacy** — FERPA and student data, also a hard constraint. `references/privacy.md`.
- **Conventions** — what step 2 turned up. `references/lenses.md`.

A lens with no surface area is skipped, not faked. The accessibility lens needs rendered output — HTML, JSX, Vue, Svelte, templates, CSS. A directory of pure data-access code has none, and the honest report says "accessibility: no user-facing surface in this target" rather than inventing something. Same for privacy in code that never touches a record about a person. The survey tells you which lenses have surface area; trust it over the instinct to report something for every heading.

## 4. Review

**For a small target**, read every file in full, then apply each lens. Reading the whole file matters — a bug is usually a mismatch between two places, and you cannot see a mismatch while looking at one of them.

**For a large target**, fan out to parallel subagents and keep the file contents out of the main context. Two ways to split:

- *By lens*, when the target is cohesive: one agent per lens over the same files. Best for a single module reviewed thoroughly.
- *By module*, when the target spans unrelated areas: one agent per subdirectory, each running all lenses. Best for a whole-project sweep.

Give each agent the target paths, the resolved standard from step 2 verbatim, the lens reference file to read, and the reporting format from `references/reporting.md`. Require it to return findings with `file:line`, a concrete failure scenario, and the rule or standard the finding rests on. An agent that returns prose impressions has not done the job — send it back.

Subagents find candidates. They do not get the last word; step 5 does.

Whatever the size, look past the file you are in. Find the callers of a function before judging its argument handling, and check whether the thing you are about to flag as missing is handled by the caller, a framework middleware, a decorator, or a type. Most false positives are context the reviewer did not go get.

## 5. Verify every finding

This is the step that makes the review worth reading. Do not skip it, and do not run it from memory.

For each candidate finding, re-open the file at the cited line and decide:

- **Is it real?** Re-read the surrounding code. Does the failure actually happen, or does something upstream already prevent it?
- **Is it in scope?** A pre-existing issue outside the target is not this review's finding. Note it in one line at the end if it is serious; do not rank it.
- **Is it already handled?** By a type, a guard clause, a framework default, a lint rule, or an explicit suppression comment. A suppression the author wrote deliberately is a decision, not a defect.
- **Can it be demonstrated?** State the inputs or the state that produce the wrong result. A finding you cannot write a failure scenario for is not verified — drop it or label it plainly as unverified.
- **Does the rule exist?** For a conventions finding, quote the line from the file that requires it. For accessibility, name the success criterion (for example 1.4.3 Contrast (Minimum)). If you cannot cite it, it is a preference and it goes in a separate short list, not the findings.

Drop everything a compiler, type checker, or configured linter would catch — they run in CI and the user does not need you for them. Drop nitpicks a senior engineer would not raise in a pull request. Drop style opinions the project has not written down.

A five-finding review where every finding is real beats a twenty-finding review the user has to triage. If verification leaves nothing, report nothing found and say what you looked for.

## 6. Report

Print the report in the conversation, ordered most severe first. Write it to a file only if the user asks.

`references/reporting.md` has the severity rubric and the full format. The shape:

```
Reviewed: src/api/ (14 files, 1,840 lines) — Node/TypeScript
Standard: ./CLAUDE.md + global ~/.claude/CLAUDE.md + eslint.config.js (run, clean)
Lenses: correctness, security, privacy  (accessibility: no user-facing surface)

HIGH  src/api/students.ts:112 — student ID written to the request log
      logRequest() interpolates req.params.id into the info-level log line.
      Directory-information rules do not cover an ID, so this is a FERPA
      education-record disclosure into a log that ships to a third party.
      Fix: log the request UUID, not the subject.

MED   src/api/roster.ts:47 — empty roster returns 500 instead of an empty list
      findAll() returns undefined for a course with no enrolments; line 47
      reads .length on it. Any new course hits this on first load.
      Fix: default to [] in findAll().

Excluded: dist/, node_modules/, package-lock.json
Also noticed (outside the target): src/db/pool.ts has no connection timeout.
```

Every finding carries the location, what goes wrong, why it is wrong with its basis, and the direction of the fix. No finding is a bare assertion.

End the report with what you did not cover: files skipped, lenses with no surface, anything the size of the target forced you to leave out. A review's blind spots are part of its result.

Then stop. Do not fix anything.

## 7. Fix, only if asked

If the user asks for fixes after seeing the report, apply them one finding at a time, most severe first, and show the changed lines — not the whole file.

Make the smallest change that resolves the finding. Do not bundle a refactor, a rename, or a dependency bump into a fix. Do not fix things that were not findings. If a fix turns out to need a larger change than the report implied, stop and say so rather than growing it quietly.

Do not commit. That is a separate decision and a separate skill.

## Reference

- `references/lenses.md` — correctness, security, and conventions: what to look for, and the false positives each one generates.
- `references/accessibility.md` — WCAG 2.1 AA review checklist, by success criterion, with what is and is not machine-checkable.
- `references/privacy.md` — FERPA and sensitive-data review: what counts as an education record, where it leaks, what to flag.
- `references/reporting.md` — severity rubric, finding format, and the rules for subagent output.
