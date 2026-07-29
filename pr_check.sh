#!/bin/bash
# PR rolling window checker — fetches and formats 2-week PR stats by business day
# Usage: pr-check [--days N] [--start YYYY-MM-DD] [--end YYYY-MM-DD]
# Default: 2-week rolling window

DAYS=14
START_OFFSET=13
END_OFFSET=0
CUSTOM_START=""
CUSTOM_END=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --days)
    DAYS="$2"
    START_OFFSET=$((DAYS - 1))
    shift 2
    ;;
  --start)
    CUSTOM_START="$2"
    shift 2
    ;;
  --end)
    CUSTOM_END="$2"
    shift 2
    ;;
  *)
    echo "Unknown option: $1"
    echo "Usage: pr-check [--days N] [--start YYYY-MM-DD] [--end YYYY-MM-DD]"
    exit 1
    ;;
  esac
done

# Determine date range
if [ -n "$CUSTOM_START" ] && [ -n "$CUSTOM_END" ]; then
  START="$CUSTOM_START"
  TOMORROW="$CUSTOM_END"
else
  START=$(date -v-${START_OFFSET}d +%Y-%m-%d)
  TOMORROW=$(date -v+${END_OFFSET}d +%Y-%m-%d)
fi

echo "Today: $(date +%Y-%m-%d) ($(date +%a))"
echo "Querying: $START to $TOMORROW"
echo ""

# Fetch data from GitHub API
RAW=$(gh api graphql -f query="query{search(query:\"org:carta is:pr is:merged author:malvadeza merged:${START}..${TOMORROW}\", type:ISSUE, first:100){nodes{... on PullRequest{closedAt}}}}" --jq '.data.search.nodes | map(.closedAt | sub("Z";"+00:00") | fromdateiso8601 | . - 7*3600 | strftime("%Y-%m-%d")) | group_by(.) | map({day: .[0], prs: length})')

# Process business days only
TOTAL=0
BD=0
declare -a DATES
declare -a DOWS_ABBR
declare -a PRS

for i in $(seq $START_OFFSET -1 0); do
  D=$(date -v-${i}d +%Y-%m-%d)
  DOW=$(date -j -f %Y-%m-%d "$D" +%u)
  [ $DOW -gt 5 ] && continue

  DOWA=$(date -j -f %Y-%m-%d "$D" +%a)
  N=$(echo "$RAW" | jq -r --arg d "$D" '.[] | select(.day == $d) | .prs')
  N=${N:-0}

  TOTAL=$((TOTAL + N))
  BD=$((BD + 1))

  DATES+=("$D")
  DOWS_ABBR+=("$DOWA")
  PRS+=("$N")
done

# Format and print table
printf "| Day | PRs |\n"
printf "|---|---|\n"
for ((i = 0; i < ${#DATES[@]}; i++)); do
  printf "| %s %s | %s |\n" "${DATES[$i]}" "${DOWS_ABBR[$i]}" "${PRS[$i]}"
done
printf "| **Total** | **%d** |\n" "$TOTAL"

echo ""
AVG=$(echo "scale=2; $TOTAL / $BD" | bc)
printf "**Average: %s PRs/business-day** across %d business days.\n" "$AVG" "$BD"
