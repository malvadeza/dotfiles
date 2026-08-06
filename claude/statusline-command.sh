#!/usr/bin/env bash
# Claude Code multi-line status line
# Line 1: Model | effort (always shown, "none" if unavailable) | context bar
#         (green 0-30% / yellow 31-70% / red 70-100% zones) - size/max | cost
# Line 2: repo | -lines removed (red) / +lines added (green) | branch
#         (always shown, "-" placeholder) | worktree (always shown, "-"
#         placeholder) | PR #123 (only shown when an open PR exists)
# Line 3: [language badge] pwd (badge based on marker files in repo root;
#         omitted if no recognized language marker is found)

input=$(cat)

# --- debug logging ---
# Writes (overwrites) the exact JSON payload Claude Code passed on stdin for
# this invocation, so we can diff it against the hand-crafted test JSON used
# during manual testing. Overwritten (not appended) each call to keep this
# bounded on disk; always reflects the most recent statusLine refresh.
DEBUG_INPUT_FILE="$HOME/.claude/statusline-debug-input.json"
DEBUG_FIELDS_FILE="$HOME/.claude/statusline-debug-fields.log"
printf '%s' "$input" > "$DEBUG_INPUT_FILE" 2>/dev/null

# --- colors ---
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
BLUE="\033[34m"
MAGENTA="\033[35m"
GRAY="\033[90m"

# Vivid zone colors used for the *filled* portion of the context bar.
# NOTE: two previous approaches to distinguishing filled vs. unfilled both
# failed because they relied on subtle color differences that collapsed
# together in Claude Code's terminal rendering (first 256-color shades of
# the same hue, then bright-vs-normal tiers of the same hue). Rather than
# rely on any color contrast at all for the fill/empty distinction, the bar
# now uses two different GLYPHS -- a solid block for filled, a hollow block
# for unfilled -- with the unfilled glyph always rendered in plain gray.
# The shape difference guarantees visible contrast regardless of how any
# given terminal renders ANSI colors.
GREEN_VIVID="\033[38;5;70m"
GREEN="\033[38;5;28m"
YELLOW_VIVID="\033[38;5;178m"
YELLOW_TRUE="\033[38;5;136m"
RED_VIVID="\033[38;5;166m"
RED="\033[38;5;130m"
CYAN_VIVID="\033[96m"
BLUE_VIVID="\033[94m"
MAGENTA_VIVID="\033[95m"

BLOCK_FILLED="█"
BLOCK_EMPTY="░"

# --- extract fields ---
# Every jq call below is wrapped so a parsing hiccup on any single field
# (missing key, unexpected type, etc.) can never abort the whole script or
# leak a jq error message into the rendered status line -- worst case the
# field just falls back to empty/0, exactly like a normal missing-optional-
# field case.
model_name=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"' 2>/dev/null)
[ -z "$model_name" ] && model_name="Claude"

# Defensive: `.effort` is only present when the current model supports
# reasoning effort (e.g. Haiku typically won't have one), so it being absent
# is expected/normal, not an error. `try/catch` also guards against the rare
# case where `.effort` shows up as a bare string instead of the documented
# `{level: ...}` shape. The effort segment always shows on line 1 -- when
# there's no effort level available we display the literal word "none"
# rather than hiding the segment.
effort_level=$(printf '%s' "$input" | jq -r 'try (.effort.level // (.effort | select(type == "string")) // empty) catch empty' 2>/dev/null)
if [ -z "$effort_level" ] || [ "$effort_level" = "null" ]; then
  effort_level="none"
fi

used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
ctx_input=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0' 2>/dev/null)
ctx_max=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 0' 2>/dev/null)

cost_usd=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
lines_added=$(printf '%s' "$input" | jq -r '.cost.total_lines_added // 0' 2>/dev/null)
lines_removed=$(printf '%s' "$input" | jq -r '.cost.total_lines_removed // 0' 2>/dev/null)

worktree_name=$(printf '%s' "$input" | jq -r '.worktree.name // .workspace.git_worktree // empty' 2>/dev/null)
repo_name=$(printf '%s' "$input" | jq -r '.workspace.repo.name // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd="$PWD"

# PR badge for the current branch, if one exists -- shown only when present.
pr_number=$(printf '%s' "$input" | jq -r '.pr.number // empty' 2>/dev/null)
pr_review_state=$(printf '%s' "$input" | jq -r '.pr.review_state // empty' 2>/dev/null)

# --- helper: format token counts like 12.3k ---
format_tokens() {
  local n="$1"
  if [ -z "$n" ] || [ "$n" = "null" ]; then
    printf '0'
    return
  fi
  if [ "$n" -ge 1000 ] 2>/dev/null; then
    awk -v n="$n" 'BEGIN { printf "%.1fk", n/1000 }'
  else
    printf '%s' "$n"
  fi
}

ctx_input_fmt=$(format_tokens "$ctx_input")
ctx_max_fmt=$(format_tokens "$ctx_max")

# --- helper: print $1 copies of character $2 (pure bash, no printf/sed
# pipeline so it can't be tripped up by locale or multi-byte UTF-8 handling
# quirks) ---
repeat_char() {
  local count="$1" ch="$2" out=""
  local i
  for (( i = 0; i < count; i++ )); do
    out="${out}${ch}"
  done
  printf '%s' "$out"
}

# --- build 3-zone context bar (green 0-30%, yellow 31-70%, red 70-100%) ---
# Wide bar (40 blocks) with a built-in zone preview: every position along
# the bar is colored according to the threshold zone IT falls in (not just
# the overall current-usage zone), so the green/yellow/red boundaries are
# always visible at a glance, even before usage reaches them.
#   - Filled positions (pos < filled): solid block (█) in that position's
#     VIVID zone color -- as usage crosses from green into yellow into red,
#     the filled portion visibly changes color zone by zone.
#   - Unfilled positions: hollow block (░) in that position's MUTED
#     (normal-tier) zone color -- a preview of the upcoming zone colors.
# The solid-vs-hollow glyph is still what guarantees filled/unfilled are
# distinguishable even if colors don't render distinctly on some terminals;
# the per-position zone coloring is a bonus visual reference on top of that.
bar_width=40
green_blocks=$(( bar_width * 30 / 100 ))   # 0-30%
yellow_blocks=$(( bar_width * 40 / 100 ))  # 31-70%
# remaining blocks (70-100%) are the red zone

# Use awk (not bash suffix-stripping) to robustly coerce the usage percentage
# to a clamped integer 0-100, regardless of decimal precision/formatting
# quirks. If `context_window.used_percentage` itself isn't provided but we do
# have raw token counts, fall back to computing the percentage ourselves
# instead of just giving up -- this covers any variant of the payload that
# omits the pre-calculated percentage while still including the raw numbers.
pct_int=$(awk -v p="$used_pct" -v ti="$ctx_input" -v cm="$ctx_max" 'BEGIN {
  if (p != "" && p != "null") {
    pi = int(p + 0)
  } else if (cm != "" && cm != "null" && (cm + 0) > 0 && ti != "" && ti != "null") {
    pi = int((ti + 0) / (cm + 0) * 100)
  } else {
    print -1
    exit
  }
  if (pi < 0) pi = 0
  if (pi > 100) pi = 100
  print pi
}')

pct_int=${pct_int:--1}
if [ "$pct_int" -ge 0 ] 2>/dev/null; then
  filled=$(( pct_int * bar_width / 100 ))
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  [ "$filled" -lt 0 ] && filled=0

  bar=""
  for (( pos = 0; pos < bar_width; pos++ )); do
    if [ "$pos" -lt "$green_blocks" ]; then
      zone_vivid="$GREEN_VIVID"
      zone_muted="$GREEN"
    elif [ "$pos" -lt "$(( green_blocks + yellow_blocks ))" ]; then
      zone_vivid="$YELLOW_VIVID"
      zone_muted="$YELLOW_TRUE"
    else
      zone_vivid="$RED_VIVID"
      zone_muted="$RED"
    fi

    if [ "$pos" -lt "$filled" ]; then
      bar="${bar}${zone_vivid}${BLOCK_FILLED}"
    else
      bar="${bar}${zone_muted}${BLOCK_EMPTY}"
    fi
  done
  bar="${bar}${RESET}"
else
  bar="${GRAY}$(repeat_char "$bar_width" "$BLOCK_EMPTY")${RESET}"
fi

# --- cost ---
if [ -n "$cost_usd" ] && [ "$cost_usd" != "null" ]; then
  cost_fmt=$(awk -v c="$cost_usd" 'BEGIN { printf "$%.2f", c }')
else
  cost_fmt="\$0.00"
fi

# --- git branch (skip optional locks, run in target dir) ---
branch=""
git_top=""
if command -v git >/dev/null 2>&1; then
  branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)
  git_top=$(git --no-optional-locks -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
fi

# --- language/environment badge, based on marker files in the repo root
# (falls back to cwd if not in a git repo). First match wins. ---
lang_root="${git_top:-$cwd}"
lang_badge=""
if [ -f "$lang_root/package.json" ]; then
  lang_badge="Node"
elif [ -f "$lang_root/go.mod" ]; then
  lang_badge="Go"
elif [ -f "$lang_root/Cargo.toml" ]; then
  lang_badge="Rust"
elif [ -f "$lang_root/pyproject.toml" ] || [ -f "$lang_root/requirements.txt" ] || [ -f "$lang_root/setup.py" ]; then
  lang_badge="Python"
elif [ -f "$lang_root/Gemfile" ]; then
  lang_badge="Ruby"
elif [ -f "$lang_root/Package.swift" ] || [ -f "$lang_root/.swift-version" ]; then
  lang_badge="Swift"
elif [ -f "$lang_root/composer.json" ]; then
  lang_badge="PHP"
elif [ -f "$lang_root/pom.xml" ] || [ -f "$lang_root/build.gradle" ] || [ -f "$lang_root/build.gradle.kts" ]; then
  lang_badge="Java"
fi

# --- line 1: model | effort | context bar - size/max | cost ---
# effort_level always shows (defaults to "none" above when unavailable).
line1="${BOLD}${model_name}${RESET} ${GRAY}|${RESET} ${MAGENTA_VIVID}${effort_level}${RESET}"
line1="${line1} ${GRAY}|${RESET} ${bar} ${GRAY}-${RESET} ${ctx_input_fmt}/${ctx_max_fmt}"
line1="${line1} ${GRAY}|${RESET} ${CYAN_VIVID}${cost_fmt}${RESET}"

# --- line 2: repo | -removed / +added | branch | worktree | PR-link ---
# branch and worktree always show now -- "-" is used as a placeholder when
# there's no git branch (not a repo) or no active --worktree session, so the
# segments/separators are always present instead of disappearing.
branch_display="${branch:--}"
worktree_display="${worktree_name}"
if [ -z "$worktree_display" ] || [ "$worktree_display" = "null" ]; then
  worktree_display="-"
fi

line2=""
if [ -n "$repo_name" ] && [ "$repo_name" != "null" ]; then
  line2="${MAGENTA_VIVID}${repo_name}${RESET} ${GRAY}|${RESET} "
fi
line2="${line2}${RED_VIVID}-${lines_removed}${RESET} ${GRAY}/${RESET} ${GREEN_VIVID}+${lines_added}${RESET}"
line2="${line2} ${GRAY}|${RESET} ${BLUE_VIVID}${branch_display}${RESET}"
line2="${line2} ${GRAY}|${RESET} ${YELLOW_TRUE}${worktree_display}${RESET}"

# PR link/badge -- only shown when an open PR exists for the current branch;
# colored by review state when available (approved=green, changes
# requested=red, pending=yellow, draft=gray, unknown=cyan).
if [ -n "$pr_number" ] && [ "$pr_number" != "null" ]; then
  case "$pr_review_state" in
    approved) pr_color="$GREEN_VIVID" ;;
    changes_requested) pr_color="$RED_VIVID" ;;
    pending) pr_color="$YELLOW_TRUE" ;;
    draft) pr_color="$GRAY" ;;
    *) pr_color="$CYAN_VIVID" ;;
  esac
  line2="${line2} ${GRAY}|${RESET} ${pr_color}PR #${pr_number}${RESET}"
fi

# --- line 3: [language badge] pwd (with $HOME shortened to ~) ---
display_dir="${cwd/#$HOME/~}"
if [ -n "$lang_badge" ]; then
  line3="${CYAN_VIVID}[${lang_badge}]${RESET} ${GRAY}${display_dir}${RESET}"
else
  line3="${GRAY}${display_dir}${RESET}"
fi

# --- debug logging: summary of every parsed/computed field ---
# Compare this against a manual run with the same test JSON to see exactly
# which field(s) Claude Code is populating differently in real usage.
{
  echo "timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "model_name: [${model_name}]"
  echo "effort_level (raw): [$(printf '%s' "$input" | jq -c '.effort // "MISSING"' 2>/dev/null)]"
  echo "effort_level (parsed): [${effort_level}]"
  echo "context_window (raw): [$(printf '%s' "$input" | jq -c '.context_window // "MISSING"' 2>/dev/null)]"
  echo "used_pct (parsed): [${used_pct}]"
  echo "ctx_input/ctx_max (parsed): [${ctx_input}]/[${ctx_max}]"
  echo "pct_int (final, incl. fallback calc): [${pct_int}]"
  echo "filled/bar_width: [${filled:-n/a}]/[${bar_width}]"
  echo "cost (raw): [$(printf '%s' "$input" | jq -c '.cost // "MISSING"' 2>/dev/null)]"
  echo "repo_name: [${repo_name}]  worktree_display: [${worktree_display}]  branch_display: [${branch_display}]"
  echo "pr (raw): [$(printf '%s' "$input" | jq -c '.pr // "MISSING"' 2>/dev/null)]  pr_number: [${pr_number}]  pr_review_state: [${pr_review_state}]"
  echo "cwd: [${cwd}]  git_top: [${git_top}]  lang_root: [${lang_root}]  lang_badge: [${lang_badge:-none}]"
  echo "---"
} > "$DEBUG_FIELDS_FILE" 2>/dev/null

printf "%b\n%b\n%b\n" "$line1" "$line2" "$line3"
