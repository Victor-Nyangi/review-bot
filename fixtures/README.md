# Self-test fixtures

`fixtures/buggy/{laravel,django,ts}/` hold small apps with planted bugs. Each `EXPECTED.md` is
the answer key: what a passing review must find, with file and line.

## Running a self-test

```bash
scripts/make-selftest-branch.sh laravel   # or django, ts
git push -u origin selftest/laravel
gh pr create --head selftest/laravel --title "Add laravel sample app" --body "Sample laravel app."
```

The script branches from the current HEAD and commits one change: the fixture copied into
`sandbox/<stack>/`, without `EXPECTED.md`. The PR diff therefore contains the bugs, and
`.github/workflows/self-test.yml` reviews it with the engine from the PR's own commit.

Pass criteria: every bug in `EXPECTED.md` is reported, exactly one summary comment exists and a
second push edits it in place, at most 5 inline comments, all on diff lines.

## Keeping the answers away from the reviewer

The review runs on a checkout of this repo, so the answer keys must not be readable:

- `.github/review-bot.yml` lists `fixtures/`, `tests/`, `scripts/make-selftest-branch.sh` and
  itself under `hide:`; `prepare.sh` deletes them from the runner's checkout before Claude
  starts.
- Claude's tools exclude `git`, so hidden files cannot be read back from the object store.
- The review workflow extracts only `scripts/{prepare,post-summary,job-summary}.sh`,
  `prompts/` and `schema/` of the bot onto the runner.
- Everything that stays visible (root README, CHANGELOG, workflows, prompts, the branch's
  commit message, the PR title and body) describes `sandbox/` neutrally. Keep it that way:
  the PR title, body and commits are readable through `gh pr view`.

Fixtures on `main` are never reviewed: only PR diffs are, and `fixtures/` is also under
`ignore:`.
