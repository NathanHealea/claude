# Ship

Run the **entire** workflow autonomously — plan → implement → stage — and stop at an opened PR,
without step-by-step approval. This is the hands-off counterpart to running `/plan`,
`/implement`, and `/stage` manually.

Use `/ship` when you want a feature taken all the way to a PR without intervening. Use the
individual commands when you want to verify and approve each commit yourself.

## Input

**`$ARGUMENTS`:** $ARGUMENTS

One of:
- a **path to a doc file** created by `/plan` (ends in `.md`) → planning is skipped, work starts
  at Implement; or
- a **feature description** (optionally prefixed with a type, e.g. `feature add user profiles`)
  → a plan doc is created first, then Implement and Stage run.

Optional flags (passed through): `--branch <name>`, `--merge-into <name>`.

If no arguments are provided, stop and ask the user for a doc path or a feature description.

## What it does

Spawn the **`workflow-runner`** agent (via the Agent tool, `subagent_type: "workflow-runner"`),
forwarding `$ARGUMENTS` verbatim as the agent's prompt. The agent:

- runs the same phase definitions the manual commands use, in **auto** mode (no approval prompts),
  in its own context window (keeping this conversation clean and conserving rate limit);
- commits each group automatically and opens the PR;
- **stops at the PR** — it never merges or runs `/release`.

While it runs, do not duplicate its work in this conversation. When it returns, relay its summary:
the branch, worktree path, **PR URL**, acceptance-criteria and build/lint/test status, and any
decision the user should double-check.

## After it returns

Merging stays manual. Tell the user to review the PR, then run `/release` from the worktree to
merge, tag, and clean up.

> Tip: for token efficiency, switch to a lighter model before shipping (`/model sonnet`) —
> planning is the only phase that benefits from a stronger model, and for a doc-path run there is
> no planning phase at all.
