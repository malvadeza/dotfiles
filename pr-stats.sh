#!/bin/bash

# PR Statistics Script
# Gets GitHub PR statistics (opened, closed, merged) for the last 2 months
# Usage: ./pr-stats.sh [username] [days_back]

set -e

# Get current GitHub user if not provided
if [ -z "$1" ]; then
    GITHUB_USER=$(gh api user --jq '.login')
else
    GITHUB_USER=$1
fi

# Default to 2 months (60 days)
DAYS_BACK=${2:-60}
START_DATE=$(date -u -v-${DAYS_BACK}d +%Y-%m-%d 2>/dev/null || date -u -d "${DAYS_BACK} days ago" +%Y-%m-%d)

echo "📊 PR Statistics for @$GITHUB_USER (last $DAYS_BACK days from $START_DATE)"
echo "============================================================"

# Overall summary
echo ""
echo "📈 Overall Summary:"
gh search prs --author="$GITHUB_USER" --created=">=$START_DATE" --limit 100 --json number,createdAt,closedAt,state | jq 'length as $total | {total: $total, opened: (map(select(.state == "open")) | length), closed: (map(select(.state == "closed")) | length), merged: (map(select(.state == "merged")) | length)}' | jq -r '"  Total PRs: \(.total)\n  Currently Open: \(.opened)\n  Closed (not merged): \(.closed)\n  Merged: \(.merged)"'

# Daily breakdown
echo ""
echo "📅 Daily Breakdown (opened, closed, merged):"
gh search prs --author="$GITHUB_USER" --created=">=$START_DATE" --limit 100 --json createdAt,closedAt,state | jq -r '.[] | ({created: (.createdAt | split("T")[0]), closed: (if .closedAt == "0001-01-01T00:00:00Z" then "" else (.closedAt | split("T")[0]) end), state: .state}) | "\(.created) opened\n\(if .closed != "" then "\(.closed) \(if .state == "merged" then "merged" else "closed" end)" else "" end)"' | grep -v '^$' | sort | uniq -c | sort -k2 -k3 | awk '{printf "  %s %s: %d\n", $2, $3, $1}' | sort

# Calculate averages
echo ""
echo "📊 Averages:"
MERGED=$(gh search prs --author="$GITHUB_USER" --created=">=$START_DATE" --limit 100 --json state | jq 'map(select(.state == "merged")) | length')
MERGE_DAYS=$(gh search prs --author="$GITHUB_USER" --created=">=$START_DATE" --limit 100 --json createdAt,closedAt,state | jq -r '.[] | ({created: (.createdAt | split("T")[0]), closed: (if .closedAt == "0001-01-01T00:00:00Z" then "" else (.closedAt | split("T")[0]) end), state: .state}) | "\(.created) opened\n\(if .closed != "" then "\(.closed) \(if .state == "merged" then "merged" else "closed" end)" else "" end)"' | grep -v '^$' | sort | uniq -c | grep merged | wc -l)

if [ "$MERGE_DAYS" -gt 0 ]; then
    AVG=$(echo "scale=2; $MERGED / $MERGE_DAYS" | bc)
    echo "  Average merged per day (with merges): $AVG"
fi

AVG_OVERALL=$(echo "scale=2; $MERGED / $DAYS_BACK" | bc)
echo "  Average merged per day (overall): $AVG_OVERALL"
