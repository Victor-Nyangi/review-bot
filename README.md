# review-bot

An automatic, stack-aware Claude code review on every pull request, as a reusable GitHub
Actions workflow. Each repo adds a 15-line caller; the workflow, scripts and prompts live here.

On every push to a non-draft PR it:

1. lists the changed files, drops lockfiles, vendored, generated and binary files, and skips
   the PR if nothing reviewable is left (docs-only, lockfile-only) or if it is too large;
2. detects the stack of each changed file (Laravel, Django, Node/Express, React, Next.js,
   otherwise generic), monorepo-aware, and builds a prompt from a base reviewer rubric, the
   matching stack checklists, the repo's own `.github/review-bot.yml`, and its
   `CLAUDE.md` / `AGENTS.md` / README;
3. runs [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action),
   which posts **at most 5 inline comments** on changed lines and returns a structured verdict;
4. creates or updates **one summary comment** on the PR (verdict, findings table, reviewed
   commit), so a later push edits it instead of adding another;
5. writes the cost and turn count to the job summary.

A run that produces no usable review fails visibly with a note on the PR; it never passes
silently.

## Set up a repo (3 steps)

1. **Key.** Create an API key in an Anthropic Console workspace with a monthly spend limit.
   Add it to the repo as the Actions secret `ANTHROPIC_API_KEY` (or as an org secret scoped to
   the repos that use it).
2. **Caller.** Copy [`examples/caller.yml`](examples/caller.yml) to
   `.github/workflows/review.yml`. It passes the secret explicitly: `secrets: inherit` does
   not work across organizations. It has no branch filter, so it works whatever the default
   branch is called.
3. **Optional config.** Copy [`examples/review-bot.yml`](examples/review-bot.yml) to
   `.github/review-bot.yml` and set focus areas, extra ignores and repo rules.

Open a PR. Drafts and Dependabot PRs are skipped; marking a draft ready triggers a review.
To review again without pushing, use **Re-run jobs** on the workflow run.

## Configuration

Workflow inputs (`with:` in the caller):

| Input | Default | Meaning |
|---|---|---|
| `bot_ref` | `v1` | Ref of this repo whose scripts and prompts are used. Keep it equal to the ref in `uses:`; if you pin `uses:` to a SHA, pass the same SHA here. |
| `bot_repo` | `Victor-Nyangi/review-bot` | Change only if you run a fork. |
| `model` | `claude-sonnet-5-5` | Claude model id. |
| `max_turns` | `30` | Agent turn limit per review. |
| `max_changed_lines` | `1500` | Above this many changed lines (after filtering) the PR gets a "too large, skipped" note instead of a review. |
| `max_inline` | `5` | Maximum inline comments per review. |

Secrets: `ANTHROPIC_API_KEY`, or `CLAUDE_CODE_OAUTH_TOKEN` as an alternative. The job fails
with a clear error if neither arrives.

`.github/review-bot.yml` in the reviewed repo (all keys optional; string or list):

| Key | Meaning |
|---|---|
| `focus` | Areas to look at hardest, e.g. "tenant scoping". |
| `ignore` | Extra path patterns to skip. `dir/` matches that directory at any depth, `a/**` everything under `a/`, `**/x.ts` that file at any depth, `*.gen.ts` matches file names. |
| `extra_rules` | Repo-specific rules a reviewer would not know. |

Built-in ignores: lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`,
`composer.lock`, `poetry.lock`, `uv.lock`, ...), `vendor/`, `node_modules/`, `dist/`,
`build/`, `public/build/`, `.next/`, `coverage/`, `*.min.*`, source maps, snapshots, images
and fonts. Docs (`*.md`, `*.rst`, `docs/`) are shown to Claude as context but never trigger a
review on their own.

Stack detection walks up from each changed file to the nearest directory with a manifest, and
also checks the repo root:

| Stack | Detected by |
|---|---|
| `laravel` | `artisan` + `composer.json` requiring `laravel/framework` |
| `django` | `manage.py`, or `django` in `pyproject.toml` / `requirements.txt` / `setup.cfg` / `Pipfile` |
| `nextjs` | `next` in `package.json` (adds `react` too) |
| `react` | `react` or `react-dom` in `package.json` |
| `node-express` | `express` in `package.json` |
| `generic` | nothing above matched |

## Cost

Default model is Sonnet 5.5. Expect roughly **$0.45–0.95 per review** on a 300–800-line diff,
so about $1–3 per PR across 2–4 pushes. Docs-only and lockfile-only PRs cost nothing (Claude
is never started). Every run writes its cost (`total_cost_usd`), turns and duration to the job
summary, so the Console spend limit can be tuned on real numbers. Start the Console workspace
at a $20/month limit.

## Design notes

- **Posts with the workflow's `GITHUB_TOKEN`, not the Claude GitHub App.** The App path
  silently skips PRs that modify the workflow file and is broken inside reusable workflows
  (upstream issue 443). The token path needs no `id-token: write`, and comments appear as
  `github-actions[bot]`. Caller permissions are just `contents: read` and
  `pull-requests: write`.
- **The summary comes from a script, not the action's sticky comment.** Claude returns JSON
  matching [`schema/review-output.json`](schema/review-output.json) via `--json-schema`;
  `post-summary.sh` finds the comment carrying `<!-- review-bot:summary -->` and PATCHes it,
  or creates it. The comment also stores `reviewed_sha` for a future incremental mode.
- **No repeated findings.** Earlier inline comments by the bot (tagged
  `<!-- review-bot:inline -->`) are listed in the prompt with an instruction not to repeat them.
- **Scripts and prompts are fetched at `bot_ref`** from codeload into `$RUNNER_TEMP`, outside
  the reviewed checkout, so they never mix with the caller's files.
- **Claude's tools are read-only** apart from the inline-comment tool: `Read`, `Grep`, `Glob`,
  `gh pr diff/view`, `git diff/log/show`. Editing, subagents, web access, `gh api` and
  `gh pr comment` are disallowed.
- **Concurrency:** one run per repo+PR; a newer push cancels the run in progress. The job times
  out after 15 minutes.
- **The action is pinned by SHA** (`v1` moves several times a week); Dependabot proposes bumps
  weekly.

## Known issues

- **Upstream issue #2047** (14 Nov 2026): agent-mode PR reviews can fail immediately with a
  hidden 401. The pinned `f431adaf` (v1.0.283) is newer than the report; whether it is fixed is
  unconfirmed until the self-test runs. If it fails that way, pin
  `anthropics/claude-code-action@4fa93a88de49bbef68b10eb15aabedf28ca0e1ed`, last reported
  working on 11 Nov 2026.
- **A PR can change its own review.** On the token path, a PR can edit the caller workflow or
  `.github/review-bot.yml` (for example to ignore everything), and the PR description is part of
  the prompt. That is acceptable for repos with a single trusted author; do not use this on
  repos that take PRs from untrusted contributors.
- **Fork PRs** get no secrets, so the job fails with "no credentials".

## Developing

```bash
bash tests/run.sh                          # offline tests, stubbed gh (needs jq, python3, git)
scripts/make-selftest-branch.sh laravel    # branch selftest/laravel with the fixture in sandbox/
```

`fixtures/buggy/{laravel,django,ts}/` hold small apps with planted bugs; each `EXPECTED.md`
lists what a passing review must find. Fixtures on `main` are never reviewed (only PR diffs
are, and this repo's `.github/review-bot.yml` ignores `fixtures/`). A self-test PR from a
`selftest/<stack>` branch puts the bugs in the diff under `sandbox/<stack>/`, and
`self-test.yml` reviews it with the engine from the PR's own commit. CI runs actionlint,
shellcheck and `tests/run.sh` (`lint.yml`).

## License

MIT, see [LICENSE](LICENSE).
