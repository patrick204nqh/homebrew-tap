# Contributing

## CI strategy

Three workflows handle all automation. Every formula change goes through a
PR — nothing is committed directly to `main` by bots.

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`ci.yml`](.github/workflows/ci.yml) | Pull request to `main` | Lint · audit · install from source · build bottle · smoke-test from bottle |
| [`release.yml`](.github/workflows/release.yml) | Push to `main` (Formula/** only) | Publish the prerelease bottle built during PR CI |
| [`sync-formulas.yml`](.github/workflows/sync-formulas.yml) | Weekly schedule (Sun 23:00 UTC) · manual dispatch | Detect new upstream versions · open a PR with updated formulas |
| [`build-ruby-runtime.yml`](.github/workflows/build-ruby-runtime.yml) | Manual dispatch only | Build a relocatable arm64 Ruby runtime · publish to `ruby-runtime-X.Y.Z` release · open PR to update sha256 in all formulas |

**PR flow:** `ci.yml` does everything needed to prove a formula is releasable —
lint, audit, install from source, build the bottle, and smoke-test the install
from that bottle. The bottle block (with its sha256) is committed back to the
PR branch so the merged formula is complete. On merge, `release.yml` simply
publishes the already-verified prerelease. No bottle is built post-merge.

See [CI pipeline diagrams](docs/architecture/diagrams/ci-pipelines.md) for visual flowcharts.

## Adding a new formula

1. Create `Formula/<tool-name>.rb` following the formula conventions below.
2. Test locally before opening a PR:

   ```bash
   brew install --build-from-source ./Formula/<tool-name>.rb
   brew test patrick204nqh/tap/<tool-name>
   brew audit --strict patrick204nqh/tap/<tool-name>
   brew style Formula/<tool-name>.rb
   bundle exec rubocop Formula/<tool-name>.rb
   ```

3. Open a PR. `ci.yml` runs automatically:
   - Lints and audits the formula
   - Installs from source and runs `brew test`
   - Builds a bottle and uploads it to a prerelease
   - Commits the bottle block back to your PR branch
   - Smoke-tests the install from that bottle
4. Review the CI results and merge. `release.yml` publishes the bottle.

## Updating an existing formula

Formulas are checked and updated automatically by
[`sync-formulas.yml`](.github/workflows/sync-formulas.yml), which runs weekly
(Sunday 23:00 UTC). It opens a PR with the new version and sha256 — CI then
builds and verifies bottles before you merge.

To trigger an out-of-band update immediately:

1. Go to **Actions → Sync Formulas → Run workflow**.
2. Review the opened PR and merge when CI passes.

## Updating the bundled Ruby runtime

Formulas in this tap bundle a relocatable Ruby runtime instead of depending on
Homebrew's `ruby` formula (which would pull in `llvm` and force source
compilation). The runtime is built once and shared across all Ruby-based
formulas.

To upgrade the runtime version:

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
- List all runtime gem dependencies as `resource` blocks with pinned SHA256s taken from the project's `Gemfile.lock`.
- Install gems to `libexec` using `r.stage { system bundled_gem, "install", ... }` and expose binaries via `write_env_script` with `GEM_HOME`/`GEM_PATH` pointed at `libexec`.
- For precompiled platform gems (e.g. nokogiri), use the `arm64-darwin` variant — bottles are arm64-only (see ADR 001).
- Order formula sections: `desc`, `homepage`, `url`, `sha256`, `license`, `RUBY_RUNTIME_VERSION` constant, dependencies, resources, `def install`, `def post_install` (if needed), `def caveats`, `test`, private helpers.
- Do not commit anything to `bottles/` — it is git-ignored. Bottles live in GitHub Releases.

## Local dev setup

```bash
bundle install   # installs rubocop for linting
```
