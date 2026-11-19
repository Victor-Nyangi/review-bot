#!/usr/bin/env bash
# post-summary.sh: create or update the single review-bot summary comment on a PR.
#
# Reads:
#   REPO, PR_NUMBER        target PR                                   (required)
#   GH_TOKEN               token with pull-requests: write
#   SKIP, SKIP_REASON      from prepare.sh
#   HEAD_SHA               commit that was reviewed (from prepare.sh)
#   CHANGED_LINES, MAX_CHANGED_LINES
#   STRUCTURED_OUTPUT      JSON string from claude-code-action
#   REVIEW_OUTCOME         outcome of the Claude step (success/failure/skipped)
#   RUN_URL, MODEL, STACKS optional, shown in the footer
#
# Exit status is non-zero when a review ran but produced no usable output, so a
# broken review is a red check, never a silent one.
set -euo pipefail

: "${REPO:?REPO is required}"
: "${PR_NUMBER:?PR_NUMBER is required}"
SKIP="${SKIP:-false}"
SKIP_REASON="${SKIP_REASON:-}"
HEAD_SHA="${HEAD_SHA:-}"
STRUCTURED_OUTPUT="${STRUCTURED_OUTPUT:-}"
REVIEW_OUTCOME="${REVIEW_OUTCOME:-unknown}"
RUN_URL="${RUN_URL:-}"
MODEL="${MODEL:-}"
STACKS="${STACKS:-}"

MARKER='<!-- review-bot:summary -->'
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

footer() {
  local parts=()
  [[ -n "$HEAD_SHA" ]] && parts+=("reviewed \`${HEAD_SHA:0:7}\`")
  [[ -n "$STACKS" ]] && parts+=("stacks: ${STACKS//,/, }")
  [[ -n "$MODEL" ]] && parts+=("model: \`$MODEL\`")
  [[ -n "$RUN_URL" ]] && parts+=("[workflow run]($RUN_URL)")
  local joined="" p
  for p in "${parts[@]}"; do joined+="${joined:+ · }$p"; done
  printf '\n<sub>review-bot%s</sub>\n' "${joined:+ · $joined}"
}

header() {
  printf '%s\n<!-- review-bot:reviewed_sha=%s -->\n' "$MARKER" "$1"
}

# Creates the marker comment, or PATCHes it in place if it already exists.
upsert_comment() {
  local body_file=$1 id
  jq -n --rawfile b "$body_file" '{body: $b}' >"$WORK/payload.json"
  id=$(gh api --paginate "repos/$REPO/issues/$PR_NUMBER/comments?per_page=100" |
    jq -s -r --arg m "$MARKER" '
      map(if type == "array" then . else [] end) | add // []
      | map(select((.body // "") | contains($m)))
      | (map(select((.user.login // "") == "github-actions[bot]")) + .)
      | first | .id // empty')
  if [[ -n "$id" ]]; then
    gh api --method PATCH "repos/$REPO/issues/comments/$id" --input "$WORK/payload.json" >/dev/null
    echo "review-bot: updated summary comment $id"
  else
    gh api --method POST "repos/$REPO/issues/$PR_NUMBER/comments" --input "$WORK/payload.json" >/dev/null
    echo "review-bot: created summary comment"
  fi
}

BODY="$WORK/body.md"

if [[ "$SKIP" == "true" ]]; then
  case "$SKIP_REASON" in
    too_large)
      {
        header ""
        echo "## Review bot: skipped, PR too large"
        echo
        echo "This PR changes **${CHANGED_LINES:-?}** lines in reviewable files, above the"
        echo "\`max_changed_lines\` limit of **${MAX_CHANGED_LINES:-1500}**. No automatic review was run."
        echo "Split the PR, or raise \`max_changed_lines\` in the caller workflow for this one."
        footer
      } >"$BODY"
      upsert_comment "$BODY"
      ;;
    *)
      echo "review-bot: skip reason '${SKIP_REASON:-none}', nothing to post."
      ;;
  esac
  exit 0
fi

valid=false
if [[ -n "$STRUCTURED_OUTPUT" ]] &&
  jq -e '
    type == "object"
    and (.verdict | IN("approve", "comment", "request_changes"))
    and (.summary_md | type == "string")
    and (.findings | type == "array")
    and all(.findings[]; type == "object"
        and (.severity | IN("blocker", "should_fix", "consider"))
        and (.title | type == "string"))' <<<"$STRUCTURED_OUTPUT" >/dev/null 2>&1; then
  valid=true
fi

if [[ "$valid" != "true" ]]; then
  {
    header ""
    echo "## Review bot: review failed"
    echo
    echo "The review for \`${HEAD_SHA:0:7}\` did not produce a usable result (Claude step: \`$REVIEW_OUTCOME\`)."
    if [[ -n "$RUN_URL" ]]; then
      echo "See the [workflow run]($RUN_URL) for the log, then use **Re-run jobs** to try again."
    else
      echo "See the workflow run for the log, then use **Re-run jobs** to try again."
    fi
    footer
  } >"$BODY"
  upsert_comment "$BODY"
  echo "::error title=review-bot::The review produced no valid structured output (Claude step outcome: $REVIEW_OUTCOME)."
  exit 1
fi

SHA="${HEAD_SHA:-$(jq -r '.reviewed_sha // ""' <<<"$STRUCTURED_OUTPUT")}"
{
  header "$SHA"
  jq -r '
    def esc: tostring | gsub("\\|"; "\\|") | gsub("[\r\n]+"; " ");
    def rank: {"blocker": 0, "should_fix": 1, "consider": 2}[.severity];
    def sevlabel: {"blocker": "Blocker", "should_fix": "Should fix", "consider": "Consider"}[.severity];
    def loc: "`\(.file // "?")\(if (.line // 0) > 0 then ":\(.line)" else "" end)`";
    (.findings | sort_by(rank)) as $f
    | ({"approve": "Looks good", "comment": "Comments", "request_changes": "Changes requested"}[.verdict]) as $v
    | ([$f[] | select(.severity == "blocker")] | length) as $b
    | ([$f[] | select(.severity == "should_fix")] | length) as $s
    | ([$f[] | select(.severity == "consider")] | length) as $c
    | "## Review bot: \($v)\n",
      (.summary_md | rtrimstr("\n")),
      "",
      (if ($f | length) == 0 then "No findings."
       else
         "**\($b)** blocker\(if $b == 1 then "" else "s" end) · **\($s)** should fix · **\($c)** consider\n",
         "| Severity | Location | Finding |",
         "|---|---|---|",
         ($f[] | "| \(sevlabel) | \(loc) | \(.title | esc) |"),
         "",
         "<details><summary>Details</summary>\n",
         ($f[] | "**\(sevlabel): \(.title)** (\(loc))\n\n\(.detail // "" | rtrimstr("\n"))\n"),
         "</details>"
       end)' <<<"$STRUCTURED_OUTPUT"
  footer
} >"$BODY"
upsert_comment "$BODY"
