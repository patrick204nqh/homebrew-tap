# Repository Rulesets

These JSON files define GitHub repository rulesets managed as code.

## Files

| File | Target | Purpose |
|------|--------|---------|
| `main-branch.json` | `main` branch | Require PR + CI before merge; block force pushes and deletion |
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

- Required status checks are `Validate / Lint` and `Validate / Audit` from `validate-pr.yml`. The dynamic `Install / <formula>` matrix job is intentionally excluded since its name depends on which formulas changed.
- Repository admins (role ID 5) can bypass the branch ruleset for emergency merges.
- The tag ruleset has no bypass — release tags are immutable once pushed.
- To update an applied ruleset, find its ID with `gh api repos/{owner}/{repo}/rulesets` then `PATCH` to `.../rulesets/{id}`.
