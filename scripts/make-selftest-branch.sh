#!/usr/bin/env bash
# make-selftest-branch.sh <laravel|django|ts>
#
# Creates the local branch selftest/<stack> from the current HEAD with one commit
# that copies fixtures/buggy/<stack>/ (minus EXPECTED.md) into sandbox/<stack>/.
# A PR from that branch has the planted bugs in its diff, so the self-test
# workflow reviews them. Nothing is pushed; push and open the PR yourself.
#
# Fixtures on main are never reviewed: only files changed in a PR's diff are,
# and this repo's .github/review-bot.yml ignores fixtures/ in any case.
set -euo pipefail

usage() { echo "usage: $0 <laravel|django|ts>" >&2; exit 2; }
[[ $# -eq 1 ]] || usage
stack=$1
[[ "$stack" =~ ^[a-z0-9-]+$ ]] || usage

root=$(git rev-parse --show-toplevel)
src="$root/fixtures/buggy/$stack"
dest_rel="sandbox/$stack"
branch="selftest/$stack"

[[ -d "$src" ]] || { echo "no fixture at fixtures/buggy/$stack" >&2; exit 1; }
if [[ -n "$(git -C "$root" status --porcelain)" ]]; then
  echo "working tree is not clean; commit or stash first" >&2
  exit 1
fi
if git -C "$root" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
  echo "branch $branch already exists; delete it first (git branch -D $branch)" >&2
  exit 1
fi

git -C "$root" switch --quiet -c "$branch"
rm -rf "${root:?}/$dest_rel"
mkdir -p "$root/$dest_rel"
# Copy everything except the answer key.
(cd "$src" && find . -type f ! -name EXPECTED.md -print0 |
  while IFS= read -r -d '' f; do
    mkdir -p "$root/$dest_rel/$(dirname "$f")"
    cp -p "$f" "$root/$dest_rel/$f"
  done)
git -C "$root" add -- "$dest_rel"
git -C "$root" commit --quiet -m "selftest: $stack fixture with planted bugs"
echo "created $branch with $(git -C "$root" ls-files -- "$dest_rel" | wc -l) files in $dest_rel/"
echo "next: git push -u origin $branch && gh pr create --fill --head $branch"
