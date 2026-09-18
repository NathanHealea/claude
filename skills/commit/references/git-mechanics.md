# Git mechanics for building a commit series

Read this when the straightforward path — `git add -- <paths>` then `git commit -F msg` — is not enough.

## Contents

- [Splitting one file across several commits](#splitting-one-file-across-several-commits)
- [Renames and moves](#renames-and-moves)
- [Deletions](#deletions)
- [Files with both staged and unstaged versions](#files-with-both-staged-and-unstaged-versions)
- [Repos with no commits yet](#repos-with-no-commits-yet)
- [Merge, rebase, or cherry-pick in progress](#merge-rebase-or-cherry-pick-in-progress)
- [Submodules](#submodules)
- [Pre-commit hooks](#pre-commit-hooks)
- [Recovery](#recovery)

## Splitting one file across several commits

When a file holds two unrelated changes, stage them separately so each commit is coherent.

`git add -p` is interactive and cannot be driven from a script. Two workable approaches:

**Line ranges, when the two changes are in clearly separate parts of the file.** Write the intermediate version of the file yourself, stage it, then restore the full version:

```bash
cp src/utils.ts /tmp/utils.full.ts        # keep the complete version
# edit src/utils.ts down to just change A (keep change B out)
git add -- src/utils.ts
cp /tmp/utils.full.ts src/utils.ts        # restore everything
git commit -F /tmp/msg-a.txt
git add -- src/utils.ts                   # change B is now what's left
```

This is easy to reason about and hard to get wrong, but you must keep the full copy safe — if you lose it, the user loses work. Copy first, always.

**Patch filtering, when the changes interleave.** Extract the diff, keep only the hunks you want, apply to the index:

```bash
git diff -- src/utils.ts > /tmp/full.patch
# edit /tmp/full.patch to keep only the hunks for change A
git apply --cached /tmp/full.patch
git commit -F /tmp/msg-a.txt
```

Hunk headers (`@@ -12,7 +12,9 @@`) must stay consistent with the lines you keep; `git apply --cached --check` first to confirm it applies cleanly. If it does not, fall back to the copy approach rather than hand-tuning line counts.

Only split when the file genuinely contains unrelated work. A file whose changes all serve one purpose is one commit's worth, and splitting it makes the history harder to read, not easier.

## Renames and moves

Git records a rename as a delete plus an add, and only detects the pairing at diff time. Stage both halves in the same commit or the history shows a file vanishing and an unrelated one appearing:

```bash
git add -- old/path.ts new/path.ts
```

`git status --porcelain` shows `R` for renames it has already detected in the index, and separate `D`/`??` lines when it has not. `git diff -M --name-status` after staging confirms it registered as a rename. A rename plus substantive edits to the same file is usually better as two commits — move first, then change — so the content diff is readable.

## Deletions

A deleted file needs `git add -- <path>` (which stages the deletion) or `git rm --cached` for stop-tracking-but-keep. Never `git rm` a file that is not already deleted in the working tree unless the user asked for it removed.

## Files with both staged and unstaged versions

If a file was staged at one version and then edited further, `git diff --cached` and `git diff` both show content for it. `git add -- <path>` in the plan picks up the current working-tree version, which is almost always what the user wants. Say so in the plan if the difference is substantive, because the staged-only version silently disappears otherwise.

## Repos with no commits yet

There is no `HEAD` to diff against, so `git diff HEAD` fails and everything shows as untracked. Group by reading the files themselves. The first commit is typically the scaffolding — README, `.gitignore`, config, license — followed by source.

## Merge, rebase, or cherry-pick in progress

`.git/MERGE_HEAD` or `.git/REBASE_HEAD` means the repo is mid-operation and the working tree contains someone else's changes as well as the user's. Splitting a merge into several commits is not possible — the merge must be committed as one. Stop, explain the state, and let the user decide whether to finish the operation first.

## Submodules

A changed submodule shows as a single line pointing at a new SHA. Commit the pointer bump on its own with a subject naming the submodule and why it moved; bundling it with application code hides a dependency change inside an unrelated diff.

## Pre-commit hooks

Hooks run on `git commit` and can do three things:

- **Reformat files and pass.** The commit succeeds but the working tree now differs. Re-run `git status`; if the hook touched files belonging to a later commit, those changes are still pending and fine. If it touched files in the commit just made, they were amended in by the hook or left staged — check before continuing.
- **Reject the commit.** Report the hook's message; the content needs fixing first. Do not retry with `--no-verify` unless the user explicitly asks — the hook exists for a reason.
- **Be slow.** Long hook runs on a multi-commit plan add up. Worth mentioning to the user if there are many commits.

## Recovery

Nothing here rewrites history, so mistakes are recoverable.

- **Wrong files in the last commit, nothing pushed:** `git reset --soft HEAD~1` returns to the pre-commit state with everything staged. Then restage correctly. Use `--soft`; `--hard` destroys work.
- **Staged the wrong thing, not yet committed:** `git reset -- <path>` unstages one file, `git reset` unstages all. The working tree is untouched either way.
- **Lost track of the original staged set:** the run recorded it in `/tmp/commit-skill-was-staged.txt` before resetting.
- **A commit went in that should not have:** `git revert <sha>` is safe and preserves history. `git reset` on already-pushed commits is not — confirm with the user before anything that rewrites.

Never `git checkout -- <path>`, `git restore <path>`, `git reset --hard`, or `git clean` while building a commit series. All four discard uncommitted work irreversibly, and uncommitted work is the entire input to this task.
