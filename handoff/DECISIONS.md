# Decisions

## Exact ticket copy only

- The branch already had a grammatical subtitle, but not the exact accepted sentence.
- Changed only the subtitle and added focused coverage; no nice-to-have copy audit was included.

## Clean staging branch

- Work is based on the repository branch where the reported copy currently ships.
- This keeps the PR limited to #248 rather than pulling unrelated team/review commits.

## Preserve current staging title during rebase

- `staging` changed the heading from `Roles & Permissions` to `Roles & permissions` after this ticket branch was created.
- The ticket changes only the subtitle, so conflict resolution keeps staging's heading and applies the approved subtitle sentence.
