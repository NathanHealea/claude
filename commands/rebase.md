# Rebase

Rebase the merge target branch onto the current working branch to bring it up to date before staging.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

- **No arguments** → use the **Merge Into** field from `.context.*.md` if present, otherwise default to `main`.
- **One argument** → treat it as the source branch to rebase from.

---

## Steps

### 1. Detect rebase source

1. If `$ARGUMENTS` is provided, use it as **`$REBASE_SOURCE`**.
2. Otherwise, find the `.context.*.md` file in the current working directory and read the **Merge Into** field. Use that as `$REBASE_SOURCE`.
3. If neither is available, default to `main`.

### 2. Verify current branch

- Run `git branch --show-current` and store as **`$CURRENT_BRANCH`**.
- If `$CURRENT_BRANCH` equals `$REBASE_SOURCE`, stop and tell the user they are already on the source branch.

### 3. Check if rebase is needed

1. Run `git fetch origin $REBASE_SOURCE` to ensure the remote is current.
2. Run `git log HEAD..origin/$REBASE_SOURCE --oneline` to list commits on the source not yet in the current branch.
3. If the output is empty, the branch is already up to date — report this and stop.

### 4. Run rebase

```bash
git rebase origin/$REBASE_SOURCE
```

### 5. Handle conflicts

If the rebase exits cleanly (no conflicts), skip to Step 7.

If conflicts are detected (git status shows `rebase in progress` or unmerged paths):

1. Run `git diff --name-only --diff-filter=U` to get the list of conflicting files.
2. For each conflicting file, determine the conflict type:
   - **Both modified** — both branches changed the same file
   - **Deleted by us** — current branch deleted it, source modified it
   - **Deleted by them** — source deleted it, current branch modified it
   - **Added by both** — both branches added a file with the same name
3. Build and display a summary table:

| File | Conflict Type | Our Change | Their Change |
|------|--------------|------------|--------------|
| `path/to/file.ts` | Both modified | description | description |

4. Prompt the user:
   - **yes** — user has manually resolved all conflicts; proceed to Step 6.
   - **adjust/(instruction)** — apply the instruction (e.g., accept ours/theirs for specific files) and re-display the table, then re-prompt.
   - **no** — abort the rebase (`git rebase --abort`) and stop.

### 6. Continue rebase after conflict resolution

```bash
git add -A
git rebase --continue
```

If further conflict rounds occur, repeat Step 5.

### 7. Report

Tell the user:
- The rebase source (`origin/$REBASE_SOURCE`) and how many commits were applied.
- Whether conflicts were resolved.
- That the branch is now up to date and ready to stage.
