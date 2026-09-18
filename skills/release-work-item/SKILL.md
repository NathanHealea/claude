---
name: release-work-item
description: Phase 4 of the work item workflow. Use when a staged work item has been reviewed and approved and is ready to land. Confirms the version and changelog are in the branch, merges into the base branch, tags the release, cleans up the worktree and branch, and closes out the work item document. Trigger on "release this", "land it", "merge this in", "ship it", "it's approved", or completion of stage-work-item.
---

# Release a work item

Phase 4 of a four-phase workflow: **Plan → Implement → Stage → Release**.

Release lands reviewed work and cleans up after it. The version bump and
changelog entry were made during Stage and reviewed with the change — this
phase confirms they are present, it does not create them.

Every step here is irreversible or awkward to undo. Confirm before acting.

## Project configuration

Read `CLAUDE.md` at the repository root before doing anything. Project config
overrides every default in this skill. Look for a `## Work Item Workflow`
section.

When a key is absent, **use the default silently** — do not ask, do not
announce the fallback.

| Key | Default |
|---|---|
| `work_items_root` | `docs` |
| `base_branch` | the repository's default branch |
| `merge_strategy` | `squash` |
| `tag_releases` | `true` when the project carries a version, else `false` |
| `tag_pattern` | `v<version>` |
| `changelog` | `CHANGELOG.md` if present |
| `worktree` | `enabled` |
| `worktree_path` | the document's front matter, else `../<repo>-worktrees/<type>-<slug>` |
| `review_mode` | `report` (see `stage-work-item`) |
| `delete_branch_after_merge` | `true` |
| `deploy_command` | none — deployment is not part of this phase |
| `verify_commands` | detected from the project |

Placeholders: `<repo>` is the repository directory name, `<type>` the work item
type, `<slug>` the kebab-case title.

## Steps

### 1. Confirm the work is ready

Read the work item document. It should be `status: staged`. If it is not, the
work has not been through Stage — send it there rather than shortcutting.

Confirm, and state to the user, that:

- the review is complete and approved. Under `review_mode: pr` that means the
  pull request is approved; under `report`, `patch`, or `none` it means the user
  says so in this conversation. Do not infer approval from silence.
- the branch is up to date with the base branch, with no conflicts
- verification passes on the current head of the branch — re-run it; a branch
  that has sat for days is not the branch that was verified. Run what the
  project defines and skip what it does not.
- if the project carries a changelog or a version file, the entry and the bump
  are present in the branch

If the project carries them and they are missing, stop and go back to Stage.
They belong to the reviewed change, so adding them here would land unreviewed
content. If the project carries neither, say so and continue.

### 2. Merge

Merge the branch into the base branch using `merge_strategy`. If the base branch
is protected against direct pushes, merge through the review host rather than
locally.

- `squash` — one commit on the base branch; write a message that summarizes the
  work item and references its slug.
- `merge` — a merge commit preserving the branch history.
- `rebase` — replay the commits onto the base branch.

If a pull request exists, merge through it so the review record stays attached.
Otherwise merge locally and push the base branch.

**Confirm with the user before merging.** State the branch, the target, the
strategy, and the commit count.

### 3. Promote the changelog

If the changelog keeps an `Unreleased` heading and this merge completes a
version, move those entries under a new heading for the released version with
today's date, and commit that to the base branch. This happens before tagging so
the tagged commit contains the released-version heading.

Skip this when there is no changelog, or when the project releases on a train
and the changelog is cut separately.

### 4. Tag

When `tag_releases` is on, tag the changelog-promotion commit — or the merge
commit when there was no changelog to promote — using `tag_pattern` and the
version now in the manifest. Annotate the tag with that version's changelog
entry. Push the tag if a remote is configured.

If the project releases several work items under one version, tag only when the
version actually changed — otherwise skip and say so.

### 5. Clean up

- If a worktree was used for this work item — the document's `worktree_path` is
  set — remove it, but only after confirming it has no uncommitted or unpushed
  changes. If it does, stop and report; do not discard the user's work. When no
  worktree was used, skip this.
- Delete the local branch when `delete_branch_after_merge` is on.
- Delete the remote branch if the project does that and the merge is confirmed
  landed.
- Prune stale worktree metadata.

### 6. Close out the document

- Set `status: released` in the front matter.
- Add the released version and tag, and the merge commit reference.
- Append a final progress log line with the date and what landed.
- If the item belongs to an epic, set its row to `released` in the epic
  document, and when every child is released, close the epic document too.

Commit the document update to the base branch. If the base branch rejects
direct pushes — a protected branch, which is common under `review_mode: pr` —
open a small follow-up pull request for the changelog promotion and document
update rather than forcing anything.

### 7. Report

Summarize: what merged, the merge commit, the tag, the version, what was
cleaned up, and anything left open — follow-up work items proposed along the
way, deferred risks, or deployment steps that are still manual.

## Deployment

Deployment is not part of this phase unless the project defines
`deploy_command` in `CLAUDE.md`. When it does, run it after the tag is pushed,
report the result, and stop — verifying a live environment is the user's call,
not an assumption to make on their behalf.

## Guardrails

- Never merge without explicit confirmation from the user.
- Never merge work that has not been reviewed and approved.
- Never merge with a failing verification.
- Never force-push the base branch, and never rewrite published history.
- Never delete a worktree or branch holding uncommitted or unpushed work.
- Never author a new changelog entry or version bump here — that is Stage's job.
  Promoting existing `Unreleased` entries under a version heading is expected.
- Never deploy unless the project explicitly configures it.
