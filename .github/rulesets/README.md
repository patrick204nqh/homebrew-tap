# Repository Rulesets

These JSON files define GitHub repository rulesets managed as code.

## Files

| File | Target | Purpose |
|------|--------|---------|
| `main-branch.json` | `main` branch | Require PR review before merge; block force pushes and deletion |
| `release-tags.json` | `v*` tags | Prevent deletion or modification of release tags |

## How to apply

```sh
gh ruleset create --file .github/rulesets/main-branch.json
gh ruleset create --file .github/rulesets/release-tags.json
```

Or via the API:

```sh
gh api repos/{owner}/{repo}/rulesets --method POST --input .github/rulesets/main-branch.json
gh api repos/{owner}/{repo}/rulesets --method POST --input .github/rulesets/release-tags.json
```

## Notes

- **No required_status_checks rule.** For a solo-maintained tap where the owner (admin) bypassed every check anyway, required checks were theater — they forced validate/bottle workflows to land status on every PR even when irrelevant (e.g. markdown-only changes triggering a full Lint/Audit run just to satisfy the gate). CI still runs visibly on code PRs; it's just not a merge blocker. If the repo ever gets outside collaborators, add `required_status_checks` back.
- Repository admins (role ID 5) can bypass the `pull_request` review rule for emergency merges.
- The tag ruleset has no bypass — release tags are immutable once pushed.
- To update an applied ruleset, find its ID with `gh api repos/{owner}/{repo}/rulesets` then `PUT` to `.../rulesets/{id}` with the JSON file as input.
