# Claude Code Instructions

## Change Execution Workflow

For any prompt that modifies files:

### 1. Plan First
List the changes (or logical groups) before modifying anything. Track them with TaskCreate using `[ ]` todo, `[~]` in progress, `[x]` completed.

### 2. One Change at a Time
- **Never auto-commit** (`git add` / `git commit`).
- After each change, state what was modified and prompt:
  - **yes** — proceed
  - **adjust/(instruction)** — revise per the instruction
  - **no** — stop
- Wait for my response before continuing.

### 3. Proceed Only After Approval
On approval: mark `[x]`, commit if applicable, move to next item. If I request changes, update and re-prompt — don't skip ahead.

### 4. Keep Task List Current
Update status immediately as it changes — don't batch.
