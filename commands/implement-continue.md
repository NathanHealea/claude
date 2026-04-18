# Implement Continue

Resume a paused implementation from its worktree **interactively**. Remaining steps are displayed grouped upfront, and you verify the diff before each commit.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

Required: a **branch slug** (e.g., `hue-value-suggestions`).

If no arguments are provided, list available worktrees by scanning `.claude/worktrees/` for directories containing `.context.*.md` files. Print each with its branch name, doc title, and paused date. Stop and ask the user to pick one.

---

## Phase 1: Assessment (main conversation)

### 1. Locate the worktree

- Verify `.claude/worktrees/{slug}` exists. If not, stop and tell the user.
- Read `.context.{slug}.md` to extract: doc path, branch name, type, description.

### 2. Verify state

Run using `git -C {worktree}`:
- `git -C {worktree} branch --show-current` — confirm correct branch.
- `git -C {worktree} log --oneline main..HEAD` — capture commits so far.
- `git -C {worktree} status` — check for uncommitted changes.

### 3. Handle uncommitted changes

If the worktree has uncommitted changes:
- Show `git -C {worktree} status` and `git -C {worktree} diff`.
- Use **AskUserQuestion**: `Uncommitted changes found from the previous session. What should I do?`
  - `Commit now` — ask for a short message, commit, then proceed.
  - `Keep & integrate` — leave in place; they'll fold into the next step's diff.
  - `Discard` — only with explicit confirmation (destructive); run `git -C {worktree} restore .`.
  - `Abort` — stop.

### 4. Print resume summary

Print:
- Branch name and worktree path
- `cd .claude/worktrees/{slug}`
- Commits already made (count + short log)

---

## Phase 2: Determine remaining work

### 5. Read the doc file

Read the doc path from the context file. Extract:
- Implementation steps (`### Implementation Steps` or `### Approach`)
- Acceptance criteria (`## Acceptance Criteria`)
- Key files (`### Key Files`, if present)

### 6. Identify what's left

Compare the doc's steps and acceptance criteria against:
- Existing commits on the branch (`git -C {worktree} log --oneline main..HEAD`)
- Current state of the code in the worktree

Identify which steps are already done and which remain.

---

## Phase 3: Display grouped remaining plan

### 7. Group the remaining steps

Group steps by natural clusters:
- If the doc uses `####` subsections or phase headings → use those.
- If steps reference distinct files/modules → group by file/module.
- Otherwise → treat each step as its own group.

### 8. Print the plan to the terminal

```
## Resuming: {Doc Title}

Branch: {branch-name}
Worktree: .claude/worktrees/{slug}
Already done: {D} steps / {total} commits
Remaining: {R} steps across {G} groups

### Group 1: {group name}
1. {step summary}

### Group 2: {group name}
2. {step summary}
...
```

Then tell the user: "I'll implement each remaining step, show you the diff, and wait for your OK before committing."

---

## Phase 4: Interactive step-by-step implementation

For each remaining step, in order:

### 9. Announce the step

One line: `→ Step {n}/{R} ({group name}): {step summary}`.

### 10. Implement the step

- Read relevant files in the worktree (absolute paths).
- Follow existing patterns — check the worktree's `CLAUDE.md` if present.
- Make the code changes with Edit/Write.
- Do NOT stage or commit yet.

**Always** use `git -C {worktree}` / `--prefix {worktree}` / absolute paths. Never chain commands with `&&`, `||`, or `;`.

### 11. Show the diff

Run `git -C {worktree} status` and `git -C {worktree} diff` (plus `git -C {worktree} diff --stat`). Display to the user. Summarize in 1-3 sentences what changed and why.

### 12. Ask the user to verify

Use **AskUserQuestion** with:

- Question: `Step {n}/{R} — {step summary}. Commit these changes and continue?`
- Options:
  - `Commit & continue` — stage changes, commit with conventional commit format, proceed.
  - `Revise` — user describes changes; do not commit. Apply revision, re-show diff, re-ask.
  - `Skip commit` — leave uncommitted, move on (warn state carries into next step's diff).
  - `Abort` — stop. Print: `/implement-continue {slug}` to resume again later.

### 13. On `Commit & continue`

- Stage only the files changed in this step (`git -C {worktree} add {files}`).
- Commit with `type(scope): description` format.
  - Single-line: `git -C {worktree} commit -m "..."`.
  - Multi-line: write to `/tmp/commit-msg.txt`, then `git -C {worktree} commit -F /tmp/commit-msg.txt`. Never use HEREDOC or `$()`.
- Proceed to the next step.

### 14. Error recovery during a step

If implementation fails:
- Attempt up to 3 fixes.
- If still broken, surface the error via **AskUserQuestion**: `Retry`, `Skip step`, `Abort`.
- Do NOT loop indefinitely.

---

## Phase 5: Final verification

### 15. Update documentation

- If ALL acceptance criteria are met → set `**Status:**` to `Done`.
- If SOME are met → set `**Status:**` to `In Progress`.
- Check off newly completed `- [ ]` criteria.
- Show diff, ask user to confirm, then commit: `docs: update status and acceptance criteria`.

### 16. Clean up context file

Remove the `## Progress` section from `.context.{slug}.md` (no longer paused). Show diff, ask user to confirm, then commit: `chore: clear paused progress from context file`.

### 17. Build / lint / test

Run from `package.json` scripts using the detected package manager:
- `build` (required)
- `lint` (if script exists)
- `test` (if script exists)

Show results. If any fail, attempt fixes (up to 3 total) with the same verify-before-commit pattern.

### 18. Present final report

Print:
- Worktree path and branch name
- `cd .claude/worktrees/{slug}`
- Summary of what was implemented this session (grouped, matching Phase 3)
- Commits this session / total on branch
- Acceptance criteria: passed / outstanding
- Build / lint / test status
- Next: `/stage` when ready
- Cleanup: `git worktree remove .claude/worktrees/{slug}`

### 19. Compact the conversation

After presenting the final report, invoke the `/compact` command to compress the conversation context. This conserves daily rate limit usage.
