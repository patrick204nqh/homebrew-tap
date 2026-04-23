# Contributing

## CI strategy

Four workflows handle all automation:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`sync-formulas.yml`](.github/workflows/sync-formulas.yml) | Weekly schedule (Sun 23:00 UTC) · manual dispatch | Detect new upstream versions · update formulas · build bottles · publish to a `tap-YYYY-MM-DD` snapshot release |
| [`build-bottles.yml`](.github/workflows/build-bottles.yml) | Push to `main` (Formula/** only) · manual dispatch | Lint · audit · build bottle · publish to a `tap-YYYY-MM-DD` snapshot release |
| [`validate-pr.yml`](.github/workflows/validate-pr.yml) | Pull request to `main` | RuboCop lint · `brew audit --strict` · `brew style` · install from source · `brew test` |
| [`build-ruby-runtime.yml`](.github/workflows/build-ruby-runtime.yml) | Manual dispatch only | Build a relocatable arm64 Ruby runtime · publish to `ruby-runtime-X.Y.Z` release · open PR to update sha256 in all formulas |

**Automated path (`sync-formulas.yml`):** runs end-to-end without any PRs or human steps. It detects new upstream releases, updates the formula version and SHA256, builds the bottle, and publishes it to a `tap-YYYY-MM-DD` snapshot release. Bot commits carry `[skip ci]` so `build-bottles.yml` does not double-build.

**Manual edit path (`build-bottles.yml`):** if you edit a formula by hand and push directly to `main`, `build-bottles.yml` picks up the changed formula file (via the `Formula/**` path filter), builds the bottle, and publishes it to a `tap-YYYY-MM-DD` snapshot release — the same scheme as the scheduled flow. Manual dispatch force-rebuilds all formulas.

All bottles are stored as release assets under `tap-YYYY-MM-DD` tags. No bottles are committed to the repository — the `bottles/` directory is git-ignored.

## Adding a new formula

1. Create `Formula/<tool-name>.rb` following the formula conventions below.
2. Test locally before opening a PR:

   ```bash
   brew install --build-from-source ./Formula/<tool-name>.rb
   brew test patrick204nqh/tap/<tool-name>
   brew audit --strict patrick204nqh/tap/<tool-name>
   brew style Formula/<tool-name>.rb
   ```

3. Run the linter:

   ```bash
   bundle exec rubocop Formula/<tool-name>.rb
   ```

4. Open a PR — `validate-pr.yml` runs lint, audit, and install automatically.
5. Merge the PR — `build-bottles.yml` builds the bottle, publishes it to the day's snapshot release, and commits the updated `bottle do` block back to the formula.

## Updating an existing formula

Formulas are checked and updated automatically by [`sync-formulas.yml`](.github/workflows/sync-formulas.yml), which runs weekly (Sunday 23:00 UTC). To trigger an out-of-band update immediately:

1. Go to **Actions → Sync Formulas → Run workflow**.

The workflow updates every formula that has a new upstream release, builds bottles, and publishes them to a snapshot release — all in one run, no PR required.

## Updating the bundled Ruby runtime

Formulas in this tap bundle a relocatable Ruby runtime instead of depending on Homebrew's `ruby` formula (which would pull in `llvm` and force source compilation). The runtime is built once and shared across all Ruby-based formulas.

To upgrade the runtime version:

1. Go to **Actions → Build Ruby Runtime → Run workflow** and enter the new version (e.g. `3.3.7`).
2. The workflow builds the runtime, publishes it to a `ruby-runtime-X.Y.Z` release, and opens a PR updating the `sha256` in every formula that uses it.
3. Review and merge the PR. The push triggers `build-bottles.yml`, which rebuilds and publishes bottles for the updated formulas.

See [ADR 001](docs/architecture/decisions/001-arm64-only-bottles.md) for the rationale behind arm64-only bottles.

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
