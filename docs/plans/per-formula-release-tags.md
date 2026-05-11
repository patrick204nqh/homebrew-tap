# Plan: Migrate bottle releases from `tap-pr-N` to `{formula}-v{version}`

## Problem

Current release scheme uses one GitHub Release per PR (`tap-pr-21`, `tap-pr-47`), where each release holds bottles for whichever formula(s) that PR touched. After every merge to `main`, `release.yml` prunes any published `tap-pr-*` release not currently referenced by a `root_url` line in `Formula/*.rb`.

Failure mode: if a formula file is removed or renamed (intentionally or by accident), the next merge to `main` will delete its published release — bottles and tag both — with no recovery path. GitHub does not retain deleted release assets.

## Goal

Replace PR-coupled release identity with stable per-formula version tags so:

- Tags don't depend on PR number → can't be orphaned by formula-file deletion
- Retention is policy-driven (keep current + N previous per formula), not reference-driven
- Intentional retirement of a formula is a separate, deliberate workflow

## Non-goals

- Changing how bottles are built (cross-platform builds, signing, etc.)
- Re-bottling existing formulas at new versions
- Touching the Ruby runtime / gem sync workflows
- Replacing the homebrew tap pattern with anything else (e.g., Cask)

## Design decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Same-version rebuild | Overwrite assets in-place at the existing `{formula}-v{version}` tag | Stable URL; simpler workflow. Acceptable since this is a personal tap and users won't pin specific bottle hashes. |
| Retention | Keep current version + 4 previous published versions per formula | Generous for low-churn tap; protects pinned users. |
| Migration order | Three sequenced PRs (add scheme → migrate existing → remove old handling) | Each step independently verifiable; minimises blast radius. |

## Target tag scheme

- Tag: `{formula}-v{version}` (e.g., `sumologic-query-v1.2.3`, `browserctl-v0.8.1`)
- One GitHub release per (formula, version) pair
- Release contains only that formula's bottles
- Created as prerelease by `bottle.yml`; flipped to published by `release.yml` on merge
- Never auto-deleted while within retention window

## Affected files

| File | Change type |
|------|-------------|
| `.github/workflows/bottle.yml` | Modify: derive tag from formula+version, replace PR-number tag |
| `.github/workflows/release.yml` | Modify: publish by per-formula tag; replace prune step with retention sweep |
| `.github/workflows/cleanup.yml` | Modify: read tag from formula `root_url` (already does this — verify behaviour) |
| `.github/actions/detect-formulas/*` | Likely no change — already emits formula names |
| `Formula/browserctl.rb` | Edit: rewrite `root_url` to new tag |
| `Formula/sumologic-query.rb` | Edit: rewrite `root_url` to new tag |
| `script/migrate-releases` (new) | One-time migration script |
| `docs/release-flow.md` (if it exists, or CONTRIBUTING.md section) | Document new scheme |

## Phased rollout

### PR 1 — Introduce new tag scheme (no behaviour change to existing releases)

**Scope**

- `bottle.yml`:
  - Compute `tag="${FORMULA}-v${VERSION}"` from formula version (version-extraction logic already exists in `release.yml` — lift it into a shared composite action or inline)
  - Upload bottles to that tag as prerelease; if the tag exists, overwrite assets (`gh release upload --clobber`)
  - Write `root_url ".../releases/download/${FORMULA}-v${VERSION}"` in the bottle block
  - Add `concurrency: bottle-${{ matrix.formula }}-${{ version }}` to prevent same-version races (current `concurrency` is per-PR; add a second guard or restructure)
- `release.yml`:
  - Read tag from formula `root_url` (already does this — verify it still works for the new shape)
  - Flip prerelease=false, rewrite notes (same as today)
  - **Keep the existing prune step temporarily** but change it to log-only (`echo "would delete: $stale_tag"`) so we can observe behaviour without acting
  - Add new retention-sweep step also in log-only mode:
    ```
    for each formula in Formula/*.rb:
      list all published {formula}-v* releases sorted by createdAt desc
      keep first 5; log the rest as "would prune"
    ```
- `cleanup.yml`: verify it correctly extracts the new tag shape from `root_url`. Adjust grep pattern only if needed — the current extractor is generic enough.

**Verification**

- Open a no-op PR that touches `browserctl.rb` (e.g., whitespace) → CI builds bottle, uploads to `browserctl-v{current-version}` as prerelease, writes new `root_url`
- Merge → `release.yml` runs, flips to published, prune step **logs** the would-delete actions only, retention sweep **logs** the would-keep/would-prune for both formulas
- Inspect logs; confirm no destructive action taken; confirm new release exists and is installable: `brew install --force-bottle patrick204nqh/tap/browserctl`

**Rollback**

Revert the PR; existing `tap-pr-*` releases remain valid (formula files still point at them until PR 2).

### PR 2 — Migrate existing formulas to new scheme

**Scope**

- `script/migrate-releases` (new, run locally with `gh` authenticated):
  ```
  for formula in browserctl sumologic-query:
    old_tag = extract root_url tag from Formula/{formula}.rb
    version = extract version from Formula/{formula}.rb
    new_tag = "{formula}-v{version}"

    if release "$new_tag" exists: skip (already migrated by PR 1's CI)
    else:
      gh release download "$old_tag" -D /tmp/{formula}
      gh release create "$new_tag" \
        --notes "Migrated from $old_tag" \
        --target main \
        /tmp/{formula}/*

    sed -i "s|releases/download/${old_tag}|releases/download/${new_tag}|" Formula/{formula}.rb
  ```
- Run the script locally; commit formula edits
- Open the PR — CI re-runs bottle.yml against the (now-renamed) tag; with `--clobber` upload this is idempotent
- Leave `tap-pr-21` and `tap-pr-47` in place (deprecated; deleted in PR 3)

**Verification**

- `brew install patrick204nqh/tap/browserctl` and `brew install patrick204nqh/tap/sumologic-query` from a clean Homebrew state, confirm bottle download succeeds from new URLs
- Confirm release pages show the migrated assets
- Confirm old `tap-pr-21` / `tap-pr-47` still resolve (for any user with cached install metadata)

**Rollback**

Revert the formula edits in PR 2; new releases remain but are unreferenced (will be retained under new policy).

### PR 3 — Activate retention policy; remove `tap-pr-*` handling

**Scope**

- `release.yml`:
  - Remove the "Prune stale tap-pr releases" step entirely
  - Switch the retention-sweep step from log-only to active deletion (delete `{formula}-v*` releases older than the most recent 5 per formula)
  - Optional: delete `tap-pr-21`, `tap-pr-47` as part of this PR (one-off cleanup), or leave them until manually retired
- `bottle.yml`: remove the `tap-pr-${PR_NUMBER}` derivation path; remove any leftover PR-number branching
- `cleanup.yml`: confirm it still works (it reads the tag from `root_url`, which is now `{formula}-v{version}`). For abandoned PRs on a brand-new version, the prerelease at that tag will be deleted — correct behaviour.
- Update `CONTRIBUTING.md` (or relevant doc) with new release-tag convention

**Verification**

- Dry-run: temporarily inject extra fake old releases (`browserctl-v0.0.1` … `v0.0.7`) and confirm the retention sweep keeps 5 and deletes 2
- Real run: merge a no-op PR; observe that no real release gets deleted (only 1 version of each formula exists)
- Close an unmerged PR that bumps a formula version; confirm `cleanup.yml` removes the corresponding prerelease

**Rollback**

Revert PR 3 (`tap-pr-*` handling and retention activation are isolated); existing per-formula releases remain valid.

## Edge cases & how they're handled

| Case | Handling |
|------|----------|
| Same-version rebuild (no upstream bump) | `gh release upload --clobber` overwrites assets at existing tag |
| Two PRs racing on the same version bump | `concurrency: bottle-{formula}-{version}` serialises; second PR's bottle build waits |
| Formula renamed | New tag created under new name; old tag stays until it falls out of the per-formula retention window (it won't — the retention key is the new formula name). **Decision:** add a manual retirement workflow for renames; do not auto-prune renamed formulas in PR 3. Track as follow-up. |
| Formula deleted | Old releases remain; not auto-pruned (retention is per-formula and the formula no longer exists). Same manual-retirement story as rename. |
| PR opened before PR 3 merges but after PR 1 | CI writes new-scheme `root_url`; safe. |
| Existing `tap-pr-21` / `tap-pr-47` URLs cached by Homebrew | Old releases still resolve until manually deleted; safe transition. |

## Open questions to resolve before PR 3 lands

1. Should renamed/deleted formulas keep their bottles forever, or do we want a separate scheduled retirement workflow with explicit opt-in?
2. Do we need any signaling to downstream users (release notes, README) when retention deletes an older bottle?

## Estimated effort

- PR 1: ~2 hours (workflow edits + dry-run logging)
- PR 2: ~1 hour (migration script + verification)
- PR 3: ~1 hour (flip retention to active, delete dead paths)

## Out of scope / explicitly deferred

- Manual formula-retirement workflow (PR 4 candidate, only if needed)
- Multi-arch bottle support beyond what bottle.yml already does
- Changing the bot identity, app token wiring, or branch-protection rules
- Sync workflows (`sync-formulas.yml`, `sync-gems.yml`, `sync-ruby-runtime.yml`) — they consume the formula files but don't care about tag shape
