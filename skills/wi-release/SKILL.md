---
name: wi-release
description: Phase 4 of the wi work item workflow. Use when a staged work item's review has been approved by the user and it is ready to land, or when the user asks for changes on a staged item. Records the approval with `wi accept`, then runs `wi release` to close out the document and changelog on the branch, merge it into the base with a --no-ff merge commit, tag that merge commit, and clean up the worktree and branch. Trigger on "accept", "approved", "release this", "land it", "merge it", "ship it", or /wi-release.
---

# Release a work item

Phase 4 of **Plan → Build → Stage → Release**. Release lands reviewed work. It
does not author anything new: the changelog entry and version bump were made and
reviewed in Stage.

Every step here is hard to undo. The user's approval must be explicit and in
their own words in this conversation. Do not infer it from silence, from a
subagent's report, or from an earlier session.

## Changes requested instead

If the user asks for changes, record them and hand back to `wi-build`:

```bash
wi reject <slug> "<what was asked for, one line>"
```

## 1. Record the approval

With `review_mode: report` (the default), the user's "accept" or "approved" in
this conversation is the review approval. Record it:

```bash
wi accept <slug>
```

With `review_mode: pr`, approval comes from the pull request. Skip `wi accept`;
`wi release` checks the PR's review decision itself.

## 2. Show the plan

```bash
wi release <slug>
```

Without `--yes` this is a dry run. It re-verifies the branch head and prints the
branch, target, strategy, commit count, version, tag, cleanup, and whether it
will push. If `wi-stage` already showed this plan and nothing has changed since,
the user's approval covers it; otherwise show it and wait for a yes.

## 3. Release

```bash
wi release <slug> --yes [--push]
```

Pass `--push` when the user asked for it or `wi config` shows `auto_push: true`
and the project has a remote. Without it, the merge commit and tag stay local,
and the remote branch is left alone.

What it does, in order:

1. On the branch: marks the document released, promotes the `Unreleased`
   changelog entries under the new version, and commits that as the branch's
   last commit.
2. Fast-forwards the local base to `origin/<base>`, then merges the branch with
   `--no-ff` (or `gh pr merge --merge` in pr mode). The merge commit is the only
   commit added to the base; its subject is `<type>(<slug>): <title>` and its
   body is the document's Summary.
3. Tags the merge commit, annotated with the version's changelog section.
4. Pushes the base and tag if asked, removes the worktree, deletes the branch
   (`git branch -d`, which refuses anything unmerged), and prunes worktree
   metadata.

If it stops after step 1, re-running `wi release <slug> --yes` resumes at the
merge.

If it refuses — base moved (`wi sync` first), main checkout not on the base
branch or dirty, verification failing, tag already exists — report the message
and stop. Do not work around it by hand.

If the push of the base branch is rejected because the branch is protected, the
merge and tag are still local. Say so, and suggest `review_mode: pr` for that
project so the merge happens on the host; never force anything.

In pr mode the close-out commit is pushed to the pull request before merging.
If the host dismisses approvals on new commits, the merge will be refused; say
so and ask the user to re-approve.

## 4. Report

The merge commit, the version and tag, what was cleaned up, whether anything
was pushed, and anything left open: follow-up work items proposed along the way,
deferred risks, manual deployment steps. If the item belongs to an epic, say
where the epic stands (`wi status`).

Deployment is not part of this workflow. If the project needs a deploy, say what
the next step is and leave it to the user.
