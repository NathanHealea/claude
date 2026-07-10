# Claude Code Config

Shared Claude Code configuration — custom commands, an orchestrator agent, shared workflow
modules, and settings. The heart of it is a consistent **plan → implement → stage → release**
development loop that can run either **manually** (you approve every commit) or **autonomously**
(hands-off to an opened PR).

Everything is built on one idea: a single source of truth in [`workflow/`](workflow/) defines
*how* each phase behaves, and the commands + agent are thin entry points that consume it.

---

## The core workflow

```
   ┌────────┐     ┌────────────┐     ┌────────┐     ┌──────────┐
   │  plan  │ ──▶ │  implement │ ──▶ │  stage │ ──▶ │  release │
   └────────┘     └────────────┘     └────────┘     └──────────┘
   write a doc    worktree +         push +          merge PR +
   with a plan    commits            open PR         tag + cleanup
                       │                                  ▲
                       ▼                                  │
              pause / continue                     (always manual)
```

Each phase hands state to the next through a single `.context.{slug}.md` file in the worktree
(the "state file" — see [`workflow/_state-file.md`](workflow/_state-file.md)).

### Two ways to run it

| | **Manual** | **Autonomous** |
|---|---|---|
| Entry point | `/plan`, `/implement`, `/stage`, `/release` | `/ship <doc-or-description>` → `workflow-runner` agent |
| Approval | You verify each diff and approve each commit | Commits each group automatically |
| Context | Runs in your main conversation | Runs in an isolated agent context |
| Stops at | Wherever you stop | The opened PR — **never merges** |

Both paths execute the **same** phase definitions; only the approval behavior (`$MODE`) differs.

> **Safety boundary:** merging a PR (`/release`) is irreversible and outward-facing, so it is
> **always a manual step** — even the autonomous run stops at the open PR and hands back to you.

---

## Command reference

### Workflow commands

| Command | Arguments | What it does | When to use |
|---|---|---|---|
| `/plan` | `epic <desc>` · `<type> <desc>` · `<path/to/doc.md>` · optional `--branch <name>` `--merge-into <name>` and `-- <extra context>` | Explores the codebase and writes/updates a doc with an implementation plan. `epic` creates a directory of feature docs; `<type> <desc>` creates one new doc; a `.md` path adds a plan to an existing doc. | Start of any non-trivial task, to produce the doc that drives implementation. |
| `/implement` | `<path/to/doc.md>` | Creates a worktree from the doc, then runs the step loop **interactively** — shows each diff and waits for your OK before every commit. | The default way to build a feature with full per-commit control. |
| `/implement-pause` | *(none — run inside the worktree)* | Commits outstanding work, records the branch in the doc, and pushes so the work can resume on any machine. | When you need to stop mid-implementation and continue later/elsewhere. |
| `/implement-continue` | `<slug> [branch]` | Fetches the branch, recreates the worktree if missing, works out what's left, and resumes the interactive loop. | To pick up a paused/aborted implementation (any machine). |
| `/rebase` | `[source-branch]` (defaults to the doc's **Merge Into**, else `main`) | Rebases the current branch onto the latest target branch, walking you through any conflicts. | Before `/stage` if the target branch moved on (`/stage` also does this automatically). |
| `/stage` | *(none — run on the feature branch)* | Verifies rebase + build + lint, bumps the version by branch type, commits, pushes, and opens a PR (GitHub or Bitbucket). | When the implementation is done and you want a PR. |
| `/release` | *(none — run inside the worktree)* | Confirms/merges the PR (squash), tags the release, deletes the branch, updates local main, removes the worktree, marks the doc done. | After the PR is reviewed and ready to merge. **Manual only.** |
| `/ship` | `<path/to/doc.md \| description>` + optional `--branch` `--merge-into` | Runs plan → implement → stage **autonomously** via the `workflow-runner` agent, stopping at the open PR. | When you want a feature taken all the way to a PR hands-off. |

### Project setup

| Command | Arguments | What it does | When to use |
|---|---|---|---|
| `/project-init` | `<name> ["context"] [--documents]` | Scaffolds a new project directory with a docs folder, a `CLAUDE.md` (with `## Testing` and `## Workflow`), and an `overview.md`. | Starting a brand-new project. |
| `/project-update` | *(none — run at project root)* | Detects project context and adds the `## Testing` / `## Workflow` sections to an existing `CLAUDE.md` (fills only what's missing). | Adopting this workflow in an existing project. |

### Docs & tracking

| Command | Arguments | What it does | When to use |
|---|---|---|---|
| `/list` | `[epic-dir]` | Lists all non-completed docs grouped into **In Progress** and **Todo**. | To see what work remains. |
| `/update-docs` | `[path.md \| epic-dir]` | Verifies each doc's acceptance criteria against the codebase, updates statuses, and syncs the overview tracker. | Periodically, to keep docs honest about what's actually built. |

### Utility

| Command | Arguments | What it does | When to use |
|---|---|---|---|
| `/commit` | `[file paths…]` | Groups changed files into logical commits (deps → config → source → tests → docs) and commits them in order after you approve the plan. | Any time you want clean, well-grouped commits outside the implement loop. |
| `/review` | `<what to plan>` | Reads the project `CLAUDE.md` and spawns a subagent that runs `/plan` with that context, then surfaces the result. | To plan work in an isolated agent that has full project context. *(This is planning, not PR review — for diff review use the built-in `/code-review`.)* |

---

## The `workflow-runner` agent

The autonomous orchestrator behind `/ship`. Given a doc path or a feature description it:

1. Runs **plan** (only if given a description), **implement**, and **stage** — following the same
   command definitions the manual commands use, but in `auto` mode (no approval prompts).
2. Commits each group automatically and opens the PR.
3. **Stops at the PR.** It never merges or runs `/release`.
4. Returns a summary: branch, worktree path, **PR URL**, acceptance-criteria and build/lint/test
   status, and anything a human should double-check.

Because it runs in its own context window, a full run doesn't clutter your main conversation.
Invoke it with `/ship`, or the model may spawn it when you ask in natural language
("take this feature all the way to a PR").

---

## Architecture: one definition, many entry points

Shared logic lives in [`workflow/`](workflow/) so a change is made once and every command + the
agent picks it up:

| Module | Defines |
|---|---|
| [`_context-detection.md`](workflow/_context-detection.md) | Docs dir, test guidance, remote type, PR template, merge target, flag parsing |
| [`_branch-naming.md`](workflow/_branch-naming.md) | Branch/slug derivation and type → prefix mapping |
| [`_state-file.md`](workflow/_state-file.md) | The `.context.*.md` contract passed between phases |
| [`_interactive-loop.md`](workflow/_interactive-loop.md) | The per-step build loop, switched by `$MODE` (`interactive` vs `auto`) |
| [`_commit-conventions.md`](workflow/_commit-conventions.md) | Commit format, staging rules, worktree hygiene, no co-author trailer |

Commands are global (`~/.claude/commands/`) and run inside any project, so they reference these
modules by absolute path (`~/.claude/workflow/…`) and read them at runtime rather than embedding
them.

```
~/.claude/
├── README.md              ← this file
├── CLAUDE.md              ← global instructions (git rules, change workflow)
├── settings.json          ← global permissions and configuration
├── commands/              ← manual entry points (also invokable as skills)
│   ├── plan.md  implement.md  implement-pause.md  implement-continue.md
│   ├── rebase.md  stage.md  release.md  ship.md
│   ├── project-init.md  project-update.md  list.md  update-docs.md
│   └── commit.md  review.md
├── agents/
│   └── workflow-runner.md ← autonomous orchestrator (used by /ship)
└── workflow/              ← single source of truth (shared modules)
    ├── _context-detection.md  _branch-naming.md  _state-file.md
    └── _interactive-loop.md   _commit-conventions.md
```

---

## Per-project configuration

The workflow reads two optional sections from the project's own `CLAUDE.md`. If they're absent,
sensible defaults are detected from the filesystem and git remote. Use `/project-init` (new) or
`/project-update` (existing) to generate them.

```markdown
## Workflow
- **Docs directory**: `docs/`            # or documents/
- **Remote type**: `github`              # or bitbucket
- **PR template**: `github-default`      # github-default | bitbucket-uo | custom
- **Default merge target**: `main`
- **Bitbucket hosts**: `git.example.edu` # only if using a self-hosted Bitbucket

## Testing
- **Framework**: Vitest
- **Test location**: colocated *.test.ts
- **Naming**: *.test.ts
- **Run command**: npm test
```

---

## Typical sessions

**Full manual control**
```
/plan feature add user profiles -- avatar uploads and a bio field
/implement docs/other/user-profiles.md      # approve each commit
/stage                                       # opens the PR
# …review the PR…
/release                                     # merge, tag, clean up
```

**Hands-off to a PR**
```
/ship docs/other/user-profiles.md            # plan already exists → implement + stage
# …review the PR…
/release                                      # you still merge manually
```

**Resume elsewhere**
```
/implement-pause                              # on machine A, inside the worktree
/implement-continue user-profiles            # on machine B
```

---

## Setup on a new computer

This directory is a git repo tracking the shareable config (commands, agents, workflow modules,
settings). Machine-specific, private, or ephemeral state — conversation history, sessions,
per-project context, caches, tasks, IDE/auth state, downloaded plugins — is git-ignored.

1. **Back up any existing config** (if you already have a `~/.claude` directory):

   ```sh
   mv ~/.claude ~/.claude.bak
   ```

2. **Clone the repo:**

   ```sh
   git clone <repo-url> ~/.claude
   ```

   Or if `~/.claude` already exists with local state you want to keep:

   ```sh
   cd ~/.claude
   git init
   git remote add origin <repo-url>
   git fetch origin
   git checkout origin/main -- .gitignore commands/ agents/ workflow/ settings.json
   ```

3. **Launch Claude Code.** It regenerates all ignored directories (`sessions/`, `cache/`,
   `projects/`, etc.) automatically on first run.

4. **Install plugins** (if needed). Downloaded marketplace plugins are not tracked — Claude Code
   re-fetches them when you install plugins through the CLI.
