---
name: commit
description: Organize a messy working tree into a reviewable series of logical commits, ordered so each commit builds on the ones before it. Use this whenever the user asks to commit their work — "commit this", "commit my changes", "can you commit", "split these changes into commits", "break this up into logical commits", "clean this up and commit it" — or invokes /commit, and also when they've finished a chunk of work and are asking what to do with a pile of uncommitted changes. Follows the commit convention in the project root CLAUDE.md, falling back to the global CLAUDE.md, then to the repo's own history. Always prints the full plan for approval before running any git command that writes, and never pushes.
---

# Commit

Turn a working tree full of intermingled changes into a clean series of commits.

The person reviewing this history later — often the user, six months from now, running `git bisect` or `git log -p` on a file — should be able to read the commits top to bottom and follow the change as a story. That is the whole goal, and it drives every decision below. A commit series that tells the story well is worth more than one that merely groups files tidily.

Two rules are absolute because violating either destroys work or surprises the user:

- **Nothing that writes runs before the user approves the plan.** Surveying is read-only. `git add`, `git commit`, `git reset` all wait.
- **Never push, never rewrite existing history.** No `git push`, `commit --amend`, `rebase`, `reset --hard`, `checkout -- <file>`, `clean`, or `stash drop`. These changes are the only copy of the user's work.
- **Commit on the branch you are already on.** Creating a branch or a tag is a separate decision that belongs to the user; quietly moving their work onto a new branch is a surprise even when it is the tidier choice. The one exception is a convention that forbids committing where you are — see step 2.

## 1. Survey

Run the bundled survey script from the repo to collect everything in one pass:

```bash
bash <skill-dir>/scripts/survey.sh [subdirectory]
```

It reports the repo root, current branch, what is staged vs. unstaged vs. untracked, a diffstat, the location of any CLAUDE.md files, recent commit subjects, and a list of files worth a second look before they go in. Pass a subdirectory only if the user scoped the request to one ("commit the stuff in `src/api`").

Then read the actual diff — `git diff`, `git diff --cached`, and the contents of new files. Grouping decisions depend on what the changes *do*, and a filename cannot tell you that. A file named `utils.ts` may hold both the new retry helper and an unrelated typo fix; only the diff shows it.

If the tree is clean, say so and stop. If the directory is not a git repo, say so and ask whether to `git init` rather than assuming.

**Files worth a second look.** The survey flags likely-unwanted additions: `.env` and other credential files, keys and certificates, `node_modules/` and other dependency directories, build output, logs, editor and OS cruft, and large binaries. These are almost always accidental — they usually mean a `.gitignore` gap rather than an intent to commit. Leave them out of the plan, list them separately as excluded, say briefly why, and offer to add them to `.gitignore`. If the user wants one in, they will say so. Debug leftovers deserve a mention too — a stray `console.log`, a commented-out block, a hardcoded localhost URL — not to block the commit, but because the user probably wants to know before it is recorded.

## 2. Resolve the commit convention

**Read every source the survey found, then decide.** Precedence settles which rule wins when two conflict; it never excuses skipping a file. Stopping at the first file that specifies a subject format is how you miss the rest — a global instruction file typically carries constraints that have nothing to do with formatting and that no project spec overrides: which branch you may commit to, whether you may create a branch at all, what must never appear in the repository record. Those still bind when a project file dictates the subject line.

Never state what a file says without having opened it. "The global file has no commit section" is a claim about a file you read, not an inference from a project file existing — and when it is wrong, every rule in the file you skipped is silently dropped.

The three sources, in precedence order:

1. **`CLAUDE.md` in the repo root** (also `.claude/CLAUDE.md` and `CLAUDE.local.md` if present). This is the project's own rule and outranks everything else.
2. **The global `~/.claude/CLAUDE.md`.** This is the user's standing instruction across every repo they work in, so it applies with the same force as a project spec — it is simply more general. Open it and read it whenever step 1 turned up nothing, and apply whatever it says about commits exactly: subject shape, casing, prefixes, required trailers, body format, issue references, length limits. Do not skip past it to the git log because the repo's history looks self-explanatory; a user who wrote a commit standard into their global file expects it followed in repos that have no opinion of their own, and inferring from history instead silently overrides them. If its commit section is genuinely absent — not merely terse — say so in the plan and move to step 3.
3. **The repo's history.** Read the last 30 subjects from `git log`. Infer the prefix scheme (`feat:`, `[JIRA-123]`, bare imperative), the casing, the tense, whether scopes are used, typical subject length, and whether bodies are common. Match what is actually there, even if it is not what you would have chosen — consistency with the surrounding history is the point.

Say in the plan which source you used and what it told you. When the history is thin, a couple of consistent commits still tell you more about what this project expects than an outside standard does — match them and say the sample was small. Reach for Conventional Commits only when there is genuinely nothing to read: an empty repo, or subjects with no discernible pattern. Name that choice explicitly either way, so the user can redirect you in one line. Apply the whole spec, not just the subject prefix. Conventions routinely govern body text, trailers, issue references, sign-offs, character limits, casing, and breaking-change markers. If the spec says every commit carries a body explaining why, then every commit carries one — a plan of bare subject lines silently drops half the convention, and it is the half that makes the history worth reading later.

A convention can also constrain *where* commits go — a rule against committing directly to `main` or `master` is common, and it collides with committing on the current branch when that is where the user happens to be. Do not resolve this yourself in either direction: creating a branch and silently committing there is as much a surprise as ignoring the rule. Say in the plan that the rule applies, that the current branch is the one it forbids, and ask whether to branch and what to call it.

Where the project spec and the global spec genuinely conflict — two different subject formats, say — the project wins, and one line in the plan is enough to note it. But conflict is narrower than it looks. A project that dictates its subject format has said nothing about branching, attribution, or what belongs in the repository record, so the global rules on those still apply in full. Take the union of the two files and let precedence decide only the handful of points where they actually disagree.

## 3. Group the changes

A commit is one reviewable idea. Aim for the smallest set of changes that leaves the tree coherent — a reviewer should be able to read the diff and say "yes, that does what the subject claims" without holding anything else in their head.

Signals that changes belong together:

- They implement one behavior. A new endpoint's route, handler, and validation are one commit, not three; separately, none of them makes sense.
- One cannot land without the other. A renamed function and its call sites belong together, because splitting them leaves a commit that does not build.
- A change and its tests. Tests land with the code they test, so `git bisect` never lands on a commit whose tests fail for a reason unrelated to the bug.

Signals that changes belong apart:

- Different intent. A bug fix and a refactor touching the same file are two commits even if they are three lines apart, because a reviewer evaluates them with different questions in mind.
- Mechanical vs. meaningful. A formatting sweep, a dependency bump, or a rename across fifty files should not be mixed with logic changes — the logic gets lost in the noise. Give mechanical churn its own commit and say so in the subject.
- Independent lifetime. If one change might plausibly be reverted without the other, they are separate commits.

A single file can span several commits. When one file genuinely holds two unrelated changes, split at hunk level rather than forcing them together — `references/git-mechanics.md` has the recipe. Do not split for the sake of it; a file whose changes all serve one purpose is one commit's worth.

Prefer fewer, well-told commits over many tiny ones. Three commits that each land a coherent piece read far better than eleven that each move a line.

## 4. Order them

Order by dependency, the way the work would have been done if it had been done cleanly from the start: foundations first, then the things built on them.

In practice that usually means: config, schema, types, and data models → shared helpers and utilities → core logic → the callers and UI that consume it → tests → docs and comments. This is a heuristic, not a ritual — the real test is whether each commit leaves the tree in a state that builds and makes sense on its own. If commit 3 calls a function introduced in commit 5, the order is wrong.

Two conventions that pay off: put pure-cleanup commits (formatting, dead code removal, dependency bumps) first, so they are out of the way before the substantive diffs begin; and if one commit is the headline change the user cares about, make sure its subject reads as the headline rather than burying it among incidentals.

## 5. Present the plan

Print the whole plan in the conversation and stop. Do not stage anything yet — staging before approval leaves the user's index rearranged if they say no.

Use this shape:

```
Convention: Conventional Commits (from ./CLAUDE.md)
Branch: feature/retry-logic  •  14 files changed

1. refactor(http): extract shared request builder
   src/http/builder.ts (new)
   src/http/client.ts
   Pulls the duplicated header/URL assembly out of client.ts so the retry
   wrapper in commit 2 has something to wrap.

2. feat(http): retry failed requests with exponential backoff
   src/http/retry.ts (new)
   src/http/client.ts
   tests/http/retry.test.ts (new)

3. docs: document retry configuration
   README.md

Excluded:
   .env.local — looks like local credentials; want this in .gitignore?
   dist/ — build output

Heads up: src/http/client.ts line 88 still has a console.log from debugging.

Commit these 3? Reply with changes if the grouping is off.
```

One line of rationale under a commit is useful when the grouping is not obvious — especially to explain why a commit comes where it does. Skip it when the subject already says everything.

When the convention requires bodies, show each message in full — subject, blank line, body, any trailers — rather than the subject alone. The body is where the reasoning lands, so it is the part most worth a second pair of eyes before it is written down. Showing only subjects invites an approval the user did not really give.

Then wait. If the user asks for changes, revise the plan and show it again rather than committing a half-corrected version.

## 6. Execute

Only after explicit approval.

Record what was already staged before touching anything, so the original state is recoverable:

```bash
git diff --cached --name-only > /tmp/commit-skill-was-staged.txt
git reset                      # unstage everything; working tree untouched
```

Then, for each commit in order:

```bash
git add -- <paths for this commit>
git commit -F <message-file>
```

Write the message to a file rather than chaining `-m` flags — it keeps multi-line bodies and special characters intact. Use `--` before paths so a filename never gets read as a flag.

Write nothing into the commit that the project's convention and its own history do not both support. That applies most sharply to attribution trailers — `Co-Authored-By`, `Generated with`, session links, tool badges. Add them only when the project explicitly asks for them; most do not, and many forbid them outright. A repository's history is a record of authorship that outlives the session, and a trailer nobody asked for is noise the user has to rewrite history to remove. Default tooling and harness conventions do not override the user's instructions here — if their CLAUDE.md says the repository record carries no reference to AI or tooling, that settles it, whatever else is configured.

If a commit fails, stop and report rather than pushing on — the remaining commits assume it landed. A pre-commit hook that rewrites files is the common case: re-check `git status`, fold the hook's changes into the commit it belongs to, and continue. A hook that rejects the commit outright means the content needs fixing first; say what it said.

## 7. Verify and report

After the last commit:

```bash
git log --oneline -<n>
git status --short
```

Confirm the log matches the approved plan and that nothing unexpected is left behind — only the files you deliberately excluded should remain uncommitted. Report the resulting log in a few lines.

Stop there. Pushing is the user's call; mention that the commits are local and unpushed, and leave it at that unless they ask.

## Reference

- `references/git-mechanics.md` — splitting a file across commits, handling renames, submodules, merge state, and recovery if something goes wrong mid-run.
