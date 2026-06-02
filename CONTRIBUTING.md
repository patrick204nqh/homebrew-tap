# Contributing

## CI strategy

Workflows are split along human vs. bot concerns, so the PR check list shows
what's human-verified separately from what's bot-authored. Every formula
change goes through a PR — nothing is committed directly to `main` by bots.

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`validate.yml`](.github/workflows/validate.yml) | Pull request to `main` | Lint · detect changed formulas · audit them. Never writes anything. |
| [`bottle.yml`](.github/workflows/bottle.yml) | Pull request touching `Formula/**` | Build bottle · upload to prerelease · commit bottle block back to PR branch · smoke-test from bottle |
| [`cleanup.yml`](.github/workflows/cleanup.yml) | Pull request close (not merged) | Delete the prerelease snapshot created during CI |
| [`release.yml`](.github/workflows/release.yml) | Push to `main` (Formula/** only) · manual dispatch | Publish the prerelease bottle built during PR CI |
| [`sync-formulas.yml`](.github/workflows/sync-formulas.yml) | Weekly schedule (Sun 23:00 UTC) · manual dispatch | Detect new upstream versions · open a PR with updated formulas |
| [`sync-gems.yml`](.github/workflows/sync-gems.yml) | Weekly schedule (Sun 22:00 UTC) · manual dispatch | Check bundled gem resource blocks for newer versions · open a PR with updates |
| [`sync-ruby-runtime.yml`](.github/workflows/sync-ruby-runtime.yml) | Weekly schedule (Sun 21:00 UTC) · manual dispatch | Check for newer Ruby patch in ruby-build · trigger `build-ruby-runtime.yml` automatically |
| [`build-ruby-runtime.yml`](.github/workflows/build-ruby-runtime.yml) | Manual dispatch · triggered by `sync-ruby-runtime.yml` | Build a relocatable arm64 Ruby runtime · publish to `ruby-runtime-X.Y.Z` release · open PR to update sha256 in all formulas |

**PR flow:** `validate.yml` and `bottle.yml` run in parallel. `validate.yml`
covers human-authored checks (lint, audit). `bottle.yml` builds the bottle,
uploads it to a prerelease, commits the bottle block back to the PR branch,
and smoke-tests the install from that bottle. Between them the PR is proven
releasable before merge. On merge, `release.yml` simply publishes the
already-verified prerelease. No bottle is built post-merge.

See [CI pipeline diagrams](docs/architecture/diagrams/ci-pipelines.md) for visual flowcharts.

## Release tags and retention

Bottle releases use a per-formula tag scheme so each formula's release lifecycle
is independent.

- **Tag format:** `{formula}-v{version}` — e.g. `browserctl-v0.13.0`,
  `sumologic-query-v1.4.2`. The tag is derived from the formula name and the
  `version` line in the `.rb` file.
- **One release per (formula, version) pair.** A release holds only that
  formula's bottles. Same-version rebuilds reuse the existing tag and overwrite
  assets in place (`gh release upload --clobber`).
- **Retention:** on every merge to `main`, `release.yml` keeps the 5 most
  recent published `{formula}-v*` releases per formula and deletes older ones
  (tag + assets). Prereleases are not counted — they live until their PR
  merges (becoming published) or closes unmerged (deleted by `cleanup.yml`).
- **Retiring a formula intentionally** (rename, deletion, deprecation): delete
  all of its `{formula}-v*` releases manually with
  `gh release delete {formula}-v{version} --yes --cleanup-tag`. The retention
  sweep is per-formula and will not auto-prune releases for a formula whose
  `.rb` file no longer exists.

Legacy `tap-pr-*` releases from the previous PR-coupled scheme are no longer
created or referenced and can be deleted manually if any remain.

## Adding a new formula

Use the generator to scaffold the formula with the correct ruby-runtime pattern:

```bash
script/new-formula <tool-name> <github-owner/repo>
# e.g. script/new-formula my-tool patrick204nqh/my-tool
```

The generator reads the current `RUBY_RUNTIME_VERSION` and sha256 from an
existing formula so the new one starts in sync. It prints a TODO checklist
with the remaining steps.

1. Fill in `desc`, `url`, `sha256`, and `license` in the generated formula.
2. Generate the gem `resource` blocks from the upstream dependency graph:

   ```bash
   bundle exec ruby script/gen-formula <tool-name>
   ```

   (see [Formula conventions](#formula-conventions) below).
3. Test locally before opening a PR:

   ```bash
   brew install --build-from-source ./Formula/<tool-name>.rb
   brew test patrick204nqh/tap/<tool-name>
   brew audit --strict patrick204nqh/tap/<tool-name>
   brew style Formula/<tool-name>.rb
   bundle exec rubocop Formula/<tool-name>.rb
   ```

4. Open a PR. `validate.yml` and `bottle.yml` run automatically in parallel:
   - `validate.yml` — lints and audits the formula (human-authored checks)
   - `bottle.yml` — builds the bottle (installs from source + `brew test` as part of bottling), uploads it to a prerelease, commits the bottle block back to your PR branch, and smoke-tests the install from that bottle
5. Review the CI results and merge. `release.yml` publishes the bottle.

## Updating an existing formula

Formulas are checked and updated automatically by
[`sync-formulas.yml`](.github/workflows/sync-formulas.yml), which runs weekly
(Sunday 23:00 UTC). It opens a PR with the new version and sha256 — CI then
builds and verifies bottles before you merge.

To trigger an out-of-band update immediately:

1. Go to **Actions → Sync Formulas → Run workflow**.
2. Review the opened PR and merge when CI passes.

## Updating bundled gem versions

Each Ruby-based formula's gem `resource` blocks are **generated**, never hand-edited.
They live between `# ── BEGIN/END generated gem resources` markers. To regenerate
them from the upstream project's dependency graph:

```bash
bundle exec ruby script/gen-formula <formula-name>
```

This resolves the formula's current source, generates a `Gemfile.lock` with
`bundle lock` (the upstream projects don't commit one), walks the project gem's
runtime dependency closure, fetches each gem's SHA256 from RubyGems (preferring
the `arm64-darwin` platform build when one exists), and rewrites the marked
section. It needs network access. It does **not** bump the formula's source
version, and it never touches the `resource "ruby-runtime"` block (managed
separately).

Because it resolves the full closure, `gen-formula` captures newly added
transitive dependencies automatically — the class of drift the older
[`sync-gems.yml`](.github/workflows/sync-gems.yml) (which only bumps versions of
gems already listed) cannot detect. `sync-gems.yml` is being retired in favour
of `gen-formula`.

## Updating the bundled Ruby runtime

Formulas in this tap bundle a relocatable Ruby runtime instead of depending on
Homebrew's `ruby` formula (which would pull in `llvm` and force source
compilation). The runtime is built once and shared across all Ruby-based
formulas.

[`sync-ruby-runtime.yml`](.github/workflows/sync-ruby-runtime.yml) runs weekly
(Sunday 21:00 UTC) and triggers `build-ruby-runtime.yml` automatically when a
newer patch release is available in ruby-build.

To upgrade the runtime manually (e.g. for an out-of-band security patch):

1. Go to **Actions → Build Ruby Runtime → Run workflow** and enter the new
   version (e.g. `3.3.7`).
2. The workflow builds the runtime, publishes it to a `ruby-runtime-X.Y.Z`
   release, and opens a PR updating the `sha256` in every formula that uses it.
3. Review and merge the PR. CI builds and verifies new bottles before merge;
   `release.yml` publishes them on merge.

See [ADR 001](docs/architecture/decisions/001-arm64-only-bottles.md) for the
rationale behind arm64-only bottles.

## Formula conventions

- All Ruby-based formulas bundle the tap's shared Ruby runtime via a `resource "ruby-runtime"` block — do not use `depends_on "ruby"` or `uses_from_macos "ruby"`.
- Runtime gem dependencies live as `resource` blocks between the `# ── BEGIN/END generated gem resources` markers and are produced by `script/gen-formula` — do not hand-edit them. The `resource "ruby-runtime"` block sits outside the markers and is managed separately.
- Install gems to `libexec` using `r.stage { system bundled_gem, "install", ... }` and expose binaries via `write_env_script` with `GEM_HOME`/`GEM_PATH` pointed at `libexec`.
- For precompiled platform gems (e.g. nokogiri), use the `arm64-darwin` variant — bottles are arm64-only (see ADR 001).
- Order formula sections: `desc`, `homepage`, `url`, `sha256`, `license`, `RUBY_RUNTIME_VERSION` constant, dependencies, resources, `def install`, `def post_install` (if needed), `def caveats`, `test`, private helpers.
- Do not commit anything to `bottles/` — it is git-ignored. Bottles live in GitHub Releases.

## Scripts

Scripts live in two directories with distinct purposes:

| Directory | Purpose | When to run |
|-----------|---------|-------------|
| `script/` | Developer tools and runtime utilities — safe to invoke locally | Anytime |
| `.github/scripts/` | CI automation — called exclusively from workflow `run:` steps | CI only |

**`script/` scripts:**
- `script/new-formula` — scaffolds a new Ruby-based formula
- `script/gen-formula` — regenerates a formula's bundled gem `resource` blocks from the upstream dependency graph (see [Updating bundled gem versions](#updating-bundled-gem-versions))
- `script/gen-completions` — regenerates shell completion files from upstream source
- `script/relocate-runtime.rb` — fixes dylib paths and shebangs after the ruby-runtime is staged; also bundled into the runtime tarball by `build-ruby-runtime.yml`

**`.github/scripts/` scripts:**
- `patch-rbconfig.rb` — appends a runtime-relocation patch to `rbconfig.rb` during the runtime build
- `update-formula.rb` — bumps formula version and SHA256 (called by `sync-formulas.yml`)
- `update-runtime-sha.rb` — updates the `ruby-runtime` SHA256 across all formulas (called by `build-ruby-runtime.yml`)
- `sync-gems.rb` — checks RubyGems.org for newer gem versions (called by `sync-gems.yml`)

If a script is useful to run locally, put it in `script/`. If it is only ever invoked from a workflow `run:` step, put it in `.github/scripts/`.

## Local dev setup

```bash
bundle install          # installs rubocop + lefthook
bundle exec lefthook install   # wires up the pre-commit hook
```

The pre-commit hook runs `rubocop` on every commit, catching style issues
before they reach CI.
