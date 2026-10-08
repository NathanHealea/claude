#!/usr/bin/env bash
# Read-only survey of a working tree, for planning a commit series.
# Usage: survey.sh [subdirectory]
# Writes nothing and changes nothing.

set -uo pipefail

SCOPE="${1:-}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "NOT_A_GIT_REPO: $(pwd)"
  exit 2
fi

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT" || exit 1

if [ -n "$SCOPE" ]; then
  PATHSPEC=("--" "$SCOPE")
else
  PATHSPEC=()
fi

hdr() { printf '\n===== %s =====\n' "$1"; }

hdr "REPO"
echo "root:   $ROOT"
echo "branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(no commits yet)')"
if ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "note:   repository has no commits yet"
fi
for state in MERGE_HEAD REBASE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG; do
  [ -e ".git/$state" ] && echo "IN_PROGRESS: $state present - resolve before committing"
done
[ -n "$SCOPE" ] && echo "scope:  $SCOPE"

hdr "STATUS (porcelain)"
git status --porcelain=v1 -uall "${PATHSPEC[@]}" | sed 's/^/  /'

hdr "STAGED FILES"
git diff --cached --name-status "${PATHSPEC[@]}" | sed 's/^/  /'

hdr "UNSTAGED TRACKED FILES"
git diff --name-status "${PATHSPEC[@]}" | sed 's/^/  /'

hdr "UNTRACKED FILES"
git ls-files --others --exclude-standard "${PATHSPEC[@]}" | sed 's/^/  /'

hdr "DIFFSTAT (tracked, staged + unstaged)"
git diff HEAD --stat "${PATHSPEC[@]}" 2>/dev/null | sed 's/^/  /' || true

hdr "UNTRACKED FILE SIZES (lines / bytes)"
git ls-files --others --exclude-standard "${PATHSPEC[@]}" | while IFS= read -r f; do
  if [ -f "$f" ]; then
    bytes=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
    if file -b --mime "$f" 2>/dev/null | grep -q 'charset=binary'; then
      printf '  %-60s binary  %s bytes\n' "$f" "$bytes"
    else
      lines=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
      printf '  %-60s %s lines  %s bytes\n' "$f" "$lines" "$bytes"
    fi
  fi
done

hdr "COMMIT CONVENTION SOURCES"
for f in CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md .claude/CLAUDE.local.md AGENTS.md; do
  [ -f "$f" ] && echo "  FOUND project: $ROOT/$f"
done
for f in "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.local.md"; do
  [ -f "$f" ] && echo "  FOUND global:  $f"
done
[ -f ".gitmessage" ] && echo "  FOUND template: $ROOT/.gitmessage"
tmpl=$(git config --get commit.template 2>/dev/null || true)
[ -n "$tmpl" ] && echo "  FOUND git config commit.template: $tmpl"
for f in .commitlintrc .commitlintrc.json .commitlintrc.js commitlint.config.js commitlint.config.cjs; do
  [ -f "$f" ] && echo "  FOUND commitlint config: $ROOT/$f (enforced convention - read it)"
done
echo "  (read these yourself; project root beats global beats git log)"

hdr "RECENT COMMIT SUBJECTS (style reference)"
git log -n 30 --format='  %s' 2>/dev/null || echo "  (no history)"

hdr "FILES WORTH A SECOND LOOK"
git status --porcelain=v1 -uall "${PATHSPEC[@]}" | awk '{ $1=""; sub(/^ +/,""); print }' | sed 's/^"//; s/"$//' | \
  grep -Ei '(^|/)\.env|(^|/)\.envrc|secret|credential|password|\.pem$|\.key$|\.p12$|\.pfx$|id_rsa|\.keystore$|(^|/)node_modules/|(^|/)vendor/|(^|/)dist/|(^|/)build/|(^|/)out/|(^|/)target/|(^|/)\.next/|(^|/)__pycache__/|\.pyc$|\.class$|\.o$|\.so$|\.dylib$|\.log$|(^|/)\.DS_Store|(^|/)Thumbs\.db|\.swp$|(^|/)\.idea/|(^|/)\.vscode/|(^|/)coverage/|\.sqlite3?$|\.db$|\.zip$|\.tar\.gz$|\.jar$' | \
  sed 's/^/  ? /' || true
echo "  (these are usually .gitignore gaps, not intended commits - exclude unless the user says otherwise)"

hdr "POSSIBLE DEBUG LEFTOVERS IN THE DIFF"
git diff HEAD "${PATHSPEC[@]}" 2>/dev/null | grep -nE '^\+' | \
  grep -Ei 'console\.(log|debug)|debugger;|pdb\.set_trace|breakpoint\(\)|System\.out\.println|dbg!|TODO:? *(remove|delete)|XXX|FIXME|localhost:[0-9]+|127\.0\.0\.1' | \
  head -20 | sed 's/^/  /' || true

hdr "END OF SURVEY"
echo "Next: read the actual diffs (git diff, git diff --cached, and new file contents)"
echo "before grouping. Filenames alone do not tell you what a change does."
