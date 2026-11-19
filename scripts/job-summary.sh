#!/usr/bin/env bash
# job-summary.sh: write what the review did and what it cost to the job summary,
# so the Console spend limit can be tuned on real numbers.
#
# Reads: SKIP, SKIP_REASON, STACKS, CHANGED_LINES, MODEL, REVIEW_OUTCOME,
#        EXECUTION_FILE (claude-code-action output), GITHUB_STEP_SUMMARY.
set -euo pipefail

SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
EXECUTION_FILE="${EXECUTION_FILE:-}"

cost="0"
turns="0"
duration=""
if [[ "${SKIP:-false}" != "true" ]]; then
  cost="n/a"
  turns="n/a"
  if [[ -n "$EXECUTION_FILE" && -f "$EXECUTION_FILE" ]]; then
    # The execution file is a JSON array of SDK messages; the last "result"
    # message carries the totals.
    result=$(jq -c '[.[]? | select(.type? == "result")] | last // {}' "$EXECUTION_FILE" 2>/dev/null || echo '{}')
    cost=$(jq -r '.total_cost_usd // empty | . * 10000 | round / 10000 | tostring' <<<"$result")
    turns=$(jq -r '.num_turns // empty | tostring' <<<"$result")
    duration=$(jq -r '.duration_ms // empty | . / 1000 | round | tostring' <<<"$result")
    cost="${cost:-n/a}"
    turns="${turns:-n/a}"
  fi
fi

{
  echo "### review-bot"
  echo
  echo "| | |"
  echo "|---|---|"
  if [[ "${SKIP:-false}" == "true" ]]; then
    echo "| Result | skipped: \`${SKIP_REASON:-unknown}\` |"
  else
    echo "| Result | Claude step \`${REVIEW_OUTCOME:-unknown}\` |"
  fi
  echo "| Stacks | ${STACKS:-n/a} |"
  echo "| Changed lines | ${CHANGED_LINES:-n/a} |"
  echo "| Model | \`${MODEL:-n/a}\` |"
  if [[ "$cost" =~ ^[0-9.]+$ ]]; then
    echo "| Cost | \$$cost |"
  else
    echo "| Cost | $cost |"
  fi
  echo "| Turns | $turns |"
  [[ -n "$duration" ]] && echo "| Duration | ${duration}s |"
  echo
} >>"$SUMMARY"
