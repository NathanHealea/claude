# Workflow Module: Step-by-Step Implementation Loop

The shared execution loop used by `/implement` and `/implement-continue` (and by the
`workflow-runner` agent). It runs a grouped list of implementation steps, committing as it goes.

The loop's behavior is governed by **`$MODE`**:

- **`interactive`** (default for `/implement` and `/implement-continue`) — show the diff for
  every step and wait for explicit user approval before committing. Honors the global `CLAUDE.md`
  "one change at a time" rule.
- **`auto`** (used by the `workflow-runner` agent) — commit each group automatically without
  prompting. Never calls `AskUserQuestion`. Stops only on an unrecoverable error.

The caller sets `$MODE` before entering the loop. If unset, assume `interactive`.

See also: `_commit-conventions.md` (commit format), `_state-file.md` (context file).

---

## Grouping the steps

Group the implementation steps by natural clusters from the doc:

- Doc uses `####` subsections or phase headings → use those as groups.
- Steps reference distinct files/modules → group by file/module.
- Steps are flat and unrelated → treat each step as its own single-step group.

Then print the grouped plan to the terminal so the full scope is visible before any code changes
(total steps, group names, per-step summaries, branch, worktree path).

In `interactive` mode, follow the plan with: "I'll implement each step, show you the diff, and
wait for your OK before committing." In `auto` mode, state that steps will be implemented and
committed group-by-group without prompting.

---

## Per-step procedure

For each step, in order:

### 1. Announce
One line: `→ Step {n}/{N} ({group name}): {step summary}`.

### 2. Implement
- Read relevant files in the worktree (absolute paths).
- Follow existing patterns — check the worktree's `CLAUDE.md` if present.
- Make the changes with Edit/Write. Do **not** stage or commit yet.
- Always use `git -C {worktree}` / absolute paths. Never chain commands with `&&`, `||`, `;`.

### 3. Show the diff
Run `git -C {worktree} status`, `git -C {worktree} diff`, and `git -C {worktree} diff --stat`.
Display the output and summarize in 1–3 sentences what changed and why.

### 4. Checkpoint — branch on `$MODE`

**`interactive`:** Use **AskUserQuestion**:

- Question: `Step {n}/{N} — {step summary}. Commit these changes and continue?`
- Options:
  - `Commit & continue` — stage the step's files, commit, proceed.
  - `Revise` — user describes changes; do **not** commit. Apply the revision, re-show the diff,
    re-ask.
  - `Skip commit` — leave changes uncommitted, move on (warn that state carries into the next
    step's diff).
  - `Abort` — stop the run. Print the resume command
    (`/implement-continue {branch-slug}`).

**`auto`:** Skip the prompt. Commit the step's files and proceed. On an unrecoverable error,
stop and return a summary of what completed and what remains (do not prompt).

### 5. Commit (on approval / in auto mode)
Stage only the files changed in this step and commit using `_commit-conventions.md`
(`type(scope): description`). Proceed to the next step.

### 6. Error recovery
If a step fails (syntax error, failing test, etc.):
- Attempt up to **3** fixes.
- `interactive`: if still broken, surface via **AskUserQuestion** with `Retry`, `Skip step`,
  `Abort`.
- `auto`: if still broken, stop and return the error plus completed/remaining summary.
- Never loop indefinitely.

---

## Final verification (both modes)

1. **Update documentation** — set the doc `**Status:**` to `Done` (all acceptance criteria met)
   or `In Progress` (some met); check off completed `- [ ]` criteria. In `interactive` mode show
   the diff and confirm before committing; in `auto` mode commit directly. Message:
   `docs: update status and acceptance criteria`.
2. **Build / lint / test** — run the `build` (required), `lint`, and `test` scripts that exist in
   `package.json` via the detected package manager. Show results. If any fail, attempt fixes (up
   to 3 total) using the same checkpoint rules for the mode.
3. **Final report** — worktree path and branch, `cd` hint, grouped summary of what was
   implemented, commit count, acceptance criteria passed/outstanding, build/lint/test status, and
   the next step (`/stage`).
