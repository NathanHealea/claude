# Implement

Set up a worktree and autonomously execute the implementation plan from a documentation file. Spawns an Agent that reads the doc, implements all steps, and returns a structured report — no user interaction required.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

Required: a **path to a documentation file** created by `/plan`:

```
/implement <path/to/doc.md>
```

If no arguments are provided, stop and tell the user to provide a doc file path. Suggest running `/plan` first if they don't have one.

---

## Phase 1: Setup (main conversation)

Lightweight orchestration — parse just enough to create the worktree, then hand off to the agent.

### 1. Parse the doc file

Read the `.md` file and extract only what's needed for worktree setup:

- **Title** — from the `#` heading
- **Type** — from the `**Type:**` field (e.g., `Feature`, `Enhancement`, `Bug`)
- **Description** — from the `## Summary` section content
- **Doc path** — the absolute path to the doc file
- **Doc directory** — the directory the doc file lives in
- **Branch** — from the `**Branch:**` field (if present)
- **Merge Into** — from the `**Merge Into:**` field (defaults to `main` if not present)

Verify the doc has an `### Implementation Steps` or `### Approach` section. If not, stop and tell the user the doc needs an implementation plan. Suggest they run `/plan {doc-path}` to add one.

#### Determine the branch name

If the doc has a **Branch** field with a non-empty value → use it directly as the branch name.

Otherwise, derive the branch name from the doc type and filename:

1. Generate the **branch slug** from the doc filename (strip `.md`, e.g., `admin-profile-linking.md` → `admin-profile-linking`).
2. Use the doc type (lowercased) as the branch prefix (e.g., `feature` → `feature/`, `bug` → `bug/`, `refactor` → `refactor/`, `hotfix` → `hotfix/`). If the type is missing, default to `feature/`.
3. Combine: `{type}/{branch-slug}` (e.g., `feature/admin-profile-linking`, `bug/login-crash`).

### 2. Pre-flight check

- Confirm we are on `main` (or the repo's default branch). If not and there are no uncommitted changes, automatically switch to `main`. If there are uncommitted changes, stop and tell the user to commit or stash first.
- Run `git pull` to ensure `main` is up to date.

### 3. Create the worktree

Determine names:
- **Branch name**: `{prefix}/{branch-slug}` (e.g., `feature/admin-profile-linking`)
- **Worktree directory**: `.claude/worktrees/{branch-slug}`

```bash
mkdir -p .claude/worktrees
git worktree add .claude/worktrees/{branch-slug} -b {branch-name}
```

### 4. Create the context file

Create `.context.{branch-slug}.md` in the worktree root:

```markdown
# Context: {Doc Title}

- **Type**: {type}
- **Branch**: {branch-name}
- **Merge Into**: {merge-into}
- **Doc directory**: {doc directory}
- **Created**: {current date YYYY-MM-DD}

## Description

{Summary from the doc file}

## Documentation

- **Doc path**: {absolute path to the doc file}
```

### 5. Determine project root

Store the absolute path to the main project root (where the worktree was created from). The agent will need this to copy config files.

---

## Phase 2: Autonomous Implementation (Agent tool)

### 6. Spawn the implementation agent

Use the **Agent tool** to launch a `general-purpose` subagent. Pass it a prompt constructed from the values gathered in Phase 1.

**IMPORTANT**: Do NOT use `isolation: "worktree"` — the worktree already exists.

**Agent prompt** (substitute `{variables}` with actual values):

```
You are implementing a feature autonomously in a git worktree. Do not ask for confirmation at any point. Work through everything start to finish.

## Paths

- **Worktree**: {absolute path to .claude/worktrees/{branch-slug}}
- **Project root**: {absolute path to main project root}
- **Doc file**: {absolute path to doc file}
- **Branch**: {branch-name}

ALL file operations must use absolute paths to the worktree.

**CRITICAL: Never use compound commands (no `&&`, `||`, or `;` to chain commands).** Run each command as a separate Bash tool call. This ensures each command matches the permission allow list. For example, do NOT run `cd /path && git add file`, instead run `git -C {worktree} add file` as its own Bash call.

For git commands, use `git -C {absolute worktree path}` to target the worktree without needing `cd`. For other tools (npm, bun, etc.), use the `--prefix` flag or equivalent, or pass absolute paths to files.

## Setup

### 1. Copy configuration files from project root into worktree

Only copy files that exist — skip missing ones silently:

- `CLAUDE.md`
- `.claude/` directory
- `.mcp.json`
- All `.env*` files from project root (use: `cp {project-root}/.env* {worktree}/ 2>/dev/null || true`)

### 2. Install dependencies

Detect from the worktree:
- `bun.lockb` → `bun install`
- `pnpm-lock.yaml` → `pnpm install`
- `yarn.lock` → `yarn install`
- `package-lock.json` or `package.json` → `npm install`
- Otherwise skip

### 3. Verify baseline build

Run the build command (detected from `package.json` scripts). If the project doesn't build on the fresh worktree, report the failure and stop — do not attempt implementation on a broken base.

## Implementation

### 4. Read the doc file

Read `{absolute path to doc file}` and extract:
- Implementation steps (from `### Implementation Steps` or `### Approach`)
- Acceptance criteria (from `## Acceptance Criteria`)
- Key files (from `### Key Files`, if present)

### 5. Create task list (if 4+ implementation steps)

If there are 4 or more implementation steps, use TaskCreate to create a task for each step plus a final "Build and lint verification" task. Use TaskUpdate to track progress (in_progress when starting, completed when done).

If fewer than 4 steps, skip task tracking and just work through them directly.

### 6. Implement each step

Work through implementation steps sequentially. For each step:

1. Read the relevant section of the doc for guidance
2. Explore the codebase — read existing files to understand patterns before writing code
3. Implement the changes
4. Verify — check for syntax errors, run quick sanity checks
5. Stage changed files and commit with conventional commit format: `type(scope): description`
   - For commit messages: use `git commit -m "..."` for single-line, or write to `/tmp/commit-msg.txt` then `git commit -F /tmp/commit-msg.txt` for multi-line. Do NOT use HEREDOC or `$()` substitution.
6. If using tasks, mark as completed via TaskUpdate

**Guidelines:**
- Follow existing patterns in the codebase (code style, naming, architecture)
- Commit after each logical unit of work, not at the end
- Don't skip steps — the plan order is intentional
- Check the project's CLAUDE.md (if it exists in the worktree) for project-specific conventions

### 7. Error recovery

If a step fails:
- Read the error carefully and attempt a fix (up to 3 attempts per step)
- If still failing after 3 attempts, commit what works, note the failure in incomplete_criteria, and move to the next step
- Do NOT loop indefinitely on a single problem

### 8. Update documentation

After all steps (or as many as possible) are complete:
- If ALL acceptance criteria are met → set `**Status:**` to `Done`
- If SOME are met → set `**Status:**` to `In Progress`
- Check off any `- [ ]` acceptance criteria that are fully implemented
- Commit the doc update

### 9. Final build/lint/test verification

Run these from `package.json` scripts (using the detected package manager):
- `build` → run it (required)
- `lint` → run it (if script exists)
- `test` → run it (if script exists)

If any fail, fix and re-run (up to 3 fix attempts total across all checks). Commit any fixes.

### 10. Return structured report

Return EXACTLY this format so the parent can parse it:

REPORT_START
worktree_path: {absolute worktree path}
branch_name: {branch name}
branch_slug: {slug}
commits_made: {number}
build_status: {pass|fail}
lint_status: {pass|fail|skipped}
test_status: {pass|fail|skipped}
doc_status: {Done|In Progress}
completed_criteria:
- {criterion 1}
- {criterion 2}
incomplete_criteria:
- {criterion}: {reason}
summary: {1-3 sentence summary}
REPORT_END
```

---

## Phase 3: Report (main conversation)

### 7. Present results

After the agent completes, parse the `REPORT_START`/`REPORT_END` block and tell the user:

- The worktree path and branch name
- `cd .claude/worktrees/{branch-slug}`
- Summary of what was implemented
- Number of commits made
- Acceptance criteria: what passed, what didn't (with reasons)
- Build / lint / test status
- Next step: review the changes, then run `/stage` when ready
- Cleanup: `git worktree remove .claude/worktrees/{branch-slug}`