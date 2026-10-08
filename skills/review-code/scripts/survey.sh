#!/usr/bin/env bash
# Read-only survey of a review target, for planning a code review.
# Usage: survey.sh [target] [--since <ref>]
#   target  a file, a directory, or . for the whole project (default: .)
# Writes nothing and changes nothing.

set -uo pipefail

TARGET="."
SINCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --since)
      SINCE="${2:-}"
      [ -z "$SINCE" ] && { echo "ERROR: --since needs a git ref" >&2; exit 2; }
      shift 2
      ;;
    --since=*)
      SINCE="${1#--since=}"
      shift
      ;;
    -*)
      echo "ERROR: unknown option $1" >&2
      exit 2
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

if [ ! -e "$TARGET" ]; then
  echo "TARGET_NOT_FOUND: $TARGET"
  exit 2
fi

ABS="$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd)/$(basename "$TARGET")"
[ -d "$TARGET" ] && ABS="$(cd "$TARGET" && pwd)"

if [ -f "$TARGET" ]; then KIND="file"; else KIND="directory"; fi

IN_GIT=no
ROOT=""
if git -C "$(dirname "$ABS")" rev-parse --show-toplevel >/dev/null 2>&1; then
  IN_GIT=yes
  ROOT="$(git -C "$(dirname "$ABS")" rev-parse --show-toplevel)"
fi

hdr() { printf '\n===== %s =====\n' "$1"; }

# Directories and files never worth reviewing. Kept as one ERE, used everywhere.
EXCLUDE_RE='(^|/)(node_modules|vendor|bower_components|dist|build|out|target|\.next|\.nuxt|\.svelte-kit|coverage|__pycache__|\.venv|venv|\.tox|\.gradle|\.terraform|Pods|migrations|__snapshots__|\.git)/|\.min\.(js|css)$|\.(lock|map|pyc|class|o|so|dylib|dll|exe|jar|war|zip|gz|tgz|png|jpe?g|gif|svg|ico|webp|woff2?|ttf|eot|mp4|mov|pdf|xlsx?|docx?|pptx?)$|(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|composer\.lock|Gemfile\.lock|poetry\.lock|Cargo\.lock|go\.sum)$'

# ---------------------------------------------------------------- file list
LIST="$(mktemp -t review-survey)"
RAW="$(mktemp -t review-survey-raw)"
trap 'rm -f "$LIST" "$RAW"' EXIT

if [ "$KIND" = "file" ]; then
  printf '%s\n' "$ABS" > "$RAW"
elif [ "$IN_GIT" = "yes" ]; then
  # Tracked + untracked-but-not-ignored, so .gitignore is respected for free.
  { git -C "$ABS" ls-files --cached --others --exclude-standard 2>/dev/null \
      | sed "s|^|$ABS/|"; } > "$RAW"
else
  find "$ABS" -type f -print > "$RAW" 2>/dev/null
fi

grep -Ev "$EXCLUDE_RE" "$RAW" > "$LIST" 2>/dev/null || true

# Restrict to files changed since a ref, if asked.
if [ -n "$SINCE" ] && [ "$IN_GIT" = "yes" ]; then
  if git -C "$ROOT" rev-parse --verify --quiet "$SINCE" >/dev/null 2>&1; then
    CHANGED="$(mktemp -t review-survey-changed)"
    git -C "$ROOT" diff --name-only "$SINCE"...HEAD 2>/dev/null | sed "s|^|$ROOT/|" > "$CHANGED"
    git -C "$ROOT" diff --name-only "$SINCE" 2>/dev/null | sed "s|^|$ROOT/|" >> "$CHANGED"
    sort -u "$CHANGED" -o "$CHANGED"
    KEEP="$(mktemp -t review-survey-keep)"
    grep -Fxf "$CHANGED" "$LIST" > "$KEEP" 2>/dev/null || true
    mv "$KEEP" "$LIST"
    rm -f "$CHANGED"
  else
    SINCE="INVALID_REF:$SINCE"
  fi
fi

NFILES=$(wc -l < "$LIST" | tr -d ' ')

# ---------------------------------------------------------------- report
hdr "TARGET"
echo "path:    $ABS"
echo "kind:    $KIND"
echo "git:     $IN_GIT${ROOT:+  (root: $ROOT)}"
if [ "$IN_GIT" = "yes" ]; then
  echo "branch:  $(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(none)')"
  DIRTY=$(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ "$DIRTY" != "0" ] && echo "note:    $DIRTY uncommitted change(s) in the tree - review reflects the working copy"
fi
[ -n "$SINCE" ] && echo "since:   $SINCE"
echo "files:   $NFILES reviewable (generated/vendored/binary excluded)"

if [ "$NFILES" = "0" ]; then
  hdr "END OF SURVEY"
  echo "Nothing reviewable at this target. Check the path, or the exclusions above."
  exit 0
fi

hdr "SIZE"
TOTAL=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  n=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
  TOTAL=$((TOTAL + ${n:-0}))
done < "$LIST"
echo "total lines: $TOTAL"
if [ "$TOTAL" -lt 1500 ]; then
  echo "strategy:    read every file directly"
elif [ "$TOTAL" -lt 25000 ]; then
  echo "strategy:    too large to read inline - fan out to parallel subagents (by lens, or by module)"
else
  echo "strategy:    TOO LARGE for one review - propose a split to the user before starting"
fi

hdr "LANGUAGES"
sed 's/.*\///' "$LIST" | grep '\.' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -15 | sed 's/^/  /'

hdr "LARGEST FILES (review these first)"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  printf '%s %s\n' "$(wc -l < "$f" 2>/dev/null | tr -d ' ')" "$f"
done < "$LIST" | sort -rn | head -10 | sed "s|$ABS/||" | sed 's/^/  /'

hdr "STANDARD SOURCES (read every one before reviewing)"
if [ -n "$ROOT" ]; then
  for f in CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md .claude/CLAUDE.local.md AGENTS.md CONTRIBUTING.md; do
    [ -f "$ROOT/$f" ] && echo "  project: $ROOT/$f"
  done
fi
# A CLAUDE.md nearer the target outranks the root one.
d="$ABS"; [ -f "$ABS" ] && d="$(dirname "$ABS")"
while [ "$d" != "/" ] && [ "$d" != "$ROOT" ]; do
  [ -f "$d/CLAUDE.md" ] && echo "  nested:  $d/CLAUDE.md  (more specific than the root file)"
  d="$(dirname "$d")"
done
for f in "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.local.md"; do
  [ -f "$f" ] || continue
  case "$f" in "$ROOT"/*) [ -n "$ROOT" ] && continue ;; esac
  echo "  global:  $f"
done
echo "  (project beats global beats linter config beats surrounding code)"

hdr "MACHINE-ENFORCED CONVENTION (run these instead of reviewing for them)"
FOUND_LINT=no
if [ -n "$ROOT" ]; then
  for f in .editorconfig .eslintrc .eslintrc.js .eslintrc.json .eslintrc.cjs eslint.config.js eslint.config.mjs \
           .prettierrc .prettierrc.json prettier.config.js tsconfig.json .stylelintrc .stylelintrc.json \
           ruff.toml .ruff.toml pyproject.toml setup.cfg .flake8 tox.ini .pylintrc mypy.ini \
           phpcs.xml .php-cs-fixer.php rustfmt.toml .golangci.yml .golangci.yaml .rubocop.yml; do
    [ -f "$ROOT/$f" ] && { echo "  $ROOT/$f"; FOUND_LINT=yes; }
  done
  for f in package.json Makefile justfile; do
    [ -f "$ROOT/$f" ] && echo "  $ROOT/$f  (check for lint/test/typecheck scripts)"
  done
fi
[ "$FOUND_LINT" = "no" ] && echo "  (none found - conventions come from CLAUDE.md and the surrounding code)"

hdr "TESTS"
if true; then
  TESTS=$(grep -Eci '(^|/)(tests?|spec|__tests__)/|\.(test|spec)\.[a-z]+$|(^|/)test_[^/]+\.py$|_test\.(go|py|rb)$' "$LIST" 2>/dev/null | head -1)
  echo "  test files under target: $TESTS"
  [ "$TESTS" = "0" ] && echo "  (no tests in scope - note missing coverage as a finding only if the project requires it)"
fi

hdr "ACCESSIBILITY SURFACE"
A11Y=$(grep -Eci '\.(html|htm|jsx|tsx|vue|svelte|astro|erb|haml|hbs|handlebars|mustache|twig|blade\.php|cshtml|razor|liquid|njk|jinja2?|css|scss|sass|less)$' "$LIST" 2>/dev/null | head -1)
echo "  user-facing files: $A11Y"
if [ "$A11Y" = "0" ]; then
  echo "  -> no rendered output in this target. Report accessibility as not applicable; do not invent findings."
else
  echo "  -> run the accessibility lens (references/accessibility.md). Sample of files:"
  grep -Ei '\.(html|htm|jsx|tsx|vue|svelte|astro|erb|haml|hbs|twig|blade\.php|cshtml|razor|liquid|njk|jinja2?|css|scss|sass|less)$' "$LIST" 2>/dev/null \
    | head -10 | sed "s|$ABS/||" | sed 's/^/     /'
fi

hdr "PRIVACY / SENSITIVE-DATA SURFACE"
PRIV=$(tr '\n' '\0' < "$LIST" | xargs -0 grep -Eil --binary-files=without-match \
  'student|ferpa|enroll|enrol|roster|transcript|grade|gpa|ssn|social.?security|date.?of.?birth|\bdob\b|duck.?id|uoid|applicant|advisee|financial.?aid|disability|accommodation' \
  2>/dev/null | sort -u | wc -l | tr -d ' ')
echo "  files mentioning person/education-record terms: $PRIV"
if [ "$PRIV" = "0" ]; then
  echo "  -> no obvious record-about-a-person handling. Confirm by eye, then report as not applicable."
else
  echo "  -> run the privacy lens (references/privacy.md). Then check every logging, error,"
  echo "     analytics, export, and third-party call site in those files."
fi

hdr "LOGGING, ERROR, AND EGRESS CALL SITES (where data leaks)"
tr '\n' '\0' < "$LIST" | xargs -0 grep -En --binary-files=without-match \
  'console\.(log|info|warn|error|debug)|logger?\.(log|info|warn|error|debug|trace)|print\(|println!|System\.out|Console\.Write|\bfetch\(|axios\.|requests\.(get|post)|HttpClient|urlopen|curl_exec|sentry|datadog|analytics\.|gtag\(|mixpanel' \
  2>/dev/null \
  | sed "s|$ABS/||" | head -25 | sed 's/^/  /'
echo "  (these are candidates, not findings - open each and see what it actually carries)"

hdr "HARDCODED SECRET CANDIDATES"
tr '\n' '\0' < "$LIST" | xargs -0 grep -Ein --binary-files=without-match \
  '(api[_-]?key|secret|passwd|password|token|bearer|private[_-]?key|client[_-]?secret|conn(ection)?[_-]?string)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}|-----BEGIN [A-Z ]*PRIVATE KEY|postgres://[^[:space:]"]*:[^[:space:]"@]*@|mysql://[^[:space:]"]*:[^[:space:]"@]*@|mongodb(\+srv)?://[^[:space:]"]*:[^[:space:]"@]*@|@uoregon\.edu' \
  2>/dev/null \
  | sed "s|$ABS/||" | head -15 | sed 's/^/  ? /'
echo "  (check each: a placeholder, a test fixture, or an env-var read is not a finding)"

hdr "RECENT CHURN (code changed lately is where bugs are)"
if [ "$IN_GIT" = "yes" ]; then
  git -C "$ROOT" log --since='3 months ago' --name-only --format='' -- "$ABS" 2>/dev/null \
    | grep -v '^$' | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
else
  echo "  (not a git repo)"
fi

hdr "END OF SURVEY"
echo "Next: read the standard sources above, then the code. Filenames and greps"
echo "locate candidates; only reading the file decides whether a candidate is real."
