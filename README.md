# Claude Code Config

Shared Claude Code configuration — custom commands, workflows, settings, and plugin config.

## What's Included

- **`commands/`** — Custom slash commands and workflows (excludes `work-*` commands)
  - `implement.md` / `implement-continue.md` / `implement-pause.md` — Implementation workflow
  - `personal-plan.md` / `personal-stage.md` / `personal-release.md` — Personal workflows
  - `project-init.md` — Project initialization
  - `update-docs.md` — Documentation updates
  - `list.md` — List utility
- **`settings.json`** — Global permissions and configuration
- **`plugins/`** — Plugin blocklist and marketplace registry (not the downloaded plugins themselves)

## What's Ignored

Everything machine-specific, private, or ephemeral:

- Conversation history and sessions
- Project-specific context and memory
- Tasks, todos, and session plans
- Caches, telemetry, debug logs
- IDE lock files and auth state
- Downloaded plugin marketplace repos
- `work-*` commands (work-specific, not shareable)

## Setup on a New Computer

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
   git checkout origin/main -- .gitignore commands/ settings.json plugins/blocklist.json plugins/known_marketplaces.json
   ```

3. **Launch Claude Code.** It will regenerate all ignored directories (`sessions/`, `cache/`, `projects/`, etc.) automatically on first run.

4. **Install plugins** (if needed). Downloaded marketplace plugins are not tracked — Claude Code will re-fetch them when you install plugins through the CLI.
