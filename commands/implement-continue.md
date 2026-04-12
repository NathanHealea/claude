# Implement Continue

Resume a paused implementation from its worktree. Spawns an Agent to complete remaining work autonomously — no user interaction required.

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

Run in the worktree directory:
- `git branch --show-current` — confirm correct branch
- `git log --oneline main..HEAD` — capture commits so far (count + log output)
- `git status` — check for uncommitted changes

### 3. Print resume summary

Print:
- Branch name and worktree path
- `cd .claude/worktrees/{slug}`
- Commits already made (count + short log)

Proceed immediately — no confirmation needed.

### 4. Determine project root

Store the absolute path to the main project root (parent of `.claude/worktrees/`).

---

## Phase 2: Autonomous Implementation (Agent tool)

### 5. Spawn the implementation agent

Use the **Agent tool** to launch a `general-purpose` subagent. Pass it a prompt constructed from the values gathered in Phase 1.

**IMPORTANT**: Do NOT use `isolation: "worktree"`.

**Agent prompt** (substitute `{variables}` with actual values):

```
You are continuing a paused implementation in a git worktree. Do not ask for confirmation at any point. Work through everything start to finish.

## Paths

- **Worktree**: {absolute path to .claude/worktrees/{slug}}
- **Project root**: {absolute path to main project root}
- **Doc file**: {absolute doc path from context file}
- **Branch**: {branch-name}

ALL file operations must use absolute paths to the worktree.

**CRITICAL: Never use compound commands (no `&&`, `||`, or `;` to chain commands).** Run each command as a separate Bash tool call. This ensures each command matches the permission allow list. For example, do NOT run `cd /path && git add file`, instead run `git -C {worktree} add file` as its own Bash call.

For git commands, use `git -C {absolute worktree path}` to target the worktree without needing `cd`. For other tools (npm, bun, etc.), use the `--prefix` flag or equivalent, or pass absolute paths to files.

## Prior work

Commits already on this branch:
{git log --oneline main..HEAD output}

{if there are uncommitted changes: "There are uncommitted changes — review and commit them first before proceeding."}

## Assessment

### 1. Read the doc file

Read `{absolute doc path}` and extract:
- Implementation steps (from `### Implementation Steps` or `### Approach`)
- Acceptance criteria (from `## Acceptance Criteria`)
- Key files (from `### Key Files`, if present)

### 2. Determine remaining work

Compare the doc's implementation steps and acceptance criteria against:
- The existing commits on the branch
- The current state of the code in the worktree

Identify which steps are already done and which remain.

## Implementation

### 3. Create task list (if 4+ remaining steps)

If there are 4 or more remaining steps, use TaskCreate for each plus a final "Build and lint verification" task. Use TaskUpdate to track progress.

If fewer than 4 remaining steps, skip task tracking.

### 4. Implement remaining steps

Work through remaining steps sequentially. For each step:

1. Read the relevant section of the doc for guidance
2. Explore the codebase — understand patterns and what was already implemented
3. Implement the changes
4. Verify — check for syntax errors, run quick sanity checks
5. Stage and commit with conventional commit format: `type(scope): description`
   - Use `git commit -m "..."` for single-line, or write to `/tmp/commit-msg.txt` then `git commit -F /tmp/commit-msg.txt`. Do NOT use HEREDOC or `$()` substitution.
6. If using tasks, mark as completed via TaskUpdate

**Guidelines:**
- Follow existing patterns in the codebase
- Commit after each logical unit of work
- Don't skip steps
- Check the project's CLAUDE.md for project-specific conventions

### 5. Error recovery

If a step fails:
- Read the error and attempt a fix (up to 3 attempts per step)
- If still failing after 3 attempts, commit what works, note the failure, and move on
- Do NOT loop indefinitely

### 6. Update documentation

After all steps (or as many as possible) are complete:
- If ALL acceptance criteria are met → set `**Status:**` to `Done`
- If SOME are met → set `**Status:**` to `In Progress`
- Check off any newly completed `- [ ]` acceptance criteria
- Commit the doc update

### 7. Final build/lint/test verification

Run from `package.json` scripts (using detected package manager):
- `build` → run it (required)
- `lint` → run it (if exists)
- `test` → run it (if exists)

If any fail, fix and re-run (up to 3 fix attempts total). Commit any fixes.

### 8. Clean up context file

Remove the `## Progress` section from `.context.{slug}.md` (no longer paused). Commit: `chore: clear paused progress from context file`.

### 9. Return structured report

Return EXACTLY this format:

REPORT_START
worktree_path: {absolute worktree path}
branch_name: {branch name}
branch_slug: {slug}
commits_this_session: {number of new commits}
total_commits: {total on branch}
build_status: {pass|fail}
lint_status: {pass|fail|skipped}
test_status: {pass|fail|skipped}
doc_status: {Done|In Progress}
completed_criteria:
- {criterion 1}
- {criterion 2}
incomplete_criteria:
- {criterion}: {reason}
summary: {1-3 sentence summary of what was implemented this session}
REPORT_END
```

---

## Phase 3: Report (main conversation)

### 6. Present results

After the agent completes, parse the `REPORT_START`/`REPORT_END` block and tell the user:

- The worktree path and branch name
- `cd .claude/worktrees/{slug}`
- Summary of what was implemented this session
- Total commits on branch
- Acceptance criteria: what passed, what didn't (with reasons)
- Build / lint / test status
- Next step: review the changes, then run `/stage` when ready
- Cleanup: `git worktree remove .claude/worktrees/{slug}`