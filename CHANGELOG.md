# Changelog

All notable changes to review-bot. Versions are git tags; callers pin the moving `v1` tag.

## Unreleased (planned v1.0.0)

- Reusable workflow `.github/workflows/review.yml` (`on: workflow_call`) running
  `anthropics/claude-code-action` pinned to `f431adaf` (v1.0.283) with the workflow's own
  `GITHUB_TOKEN`.
- `scripts/prepare.sh`: filters generated/vendored/lock/binary files and docs, skips PRs with
  nothing reviewable or more than `max_changed_lines`, detects Laravel, Django, Node/Express,
  React and Next.js per directory (monorepo-aware), reads `.github/review-bot.yml`, lists the
  bot's earlier inline findings, and assembles the prompt.
- `scripts/post-summary.sh`: one summary comment per PR, marked with
  `<!-- review-bot:summary -->` and updated in place; a review with no usable output posts a
  failure note and fails the job.
- `scripts/job-summary.sh`: cost, turns and duration in the job summary.
- Prompts: base reviewer rubric plus checklists for laravel, django, node-express, react,
  nextjs and generic.
- Fixtures with planted bugs (Laravel, Django, Express + React), `make-selftest-branch.sh`,
  self-test workflow, offline tests (`tests/run.sh`), actionlint + shellcheck CI.
