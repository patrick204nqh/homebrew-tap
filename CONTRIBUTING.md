# Contributing

## CI strategy

Three workflows handle all automation:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`snapshot.yml`](.github/workflows/snapshot.yml) | Weekly schedule · manual dispatch | Detect new upstream versions · update formulas · build and publish bottles · tag a tap snapshot release |
| [`ci.yml`](.github/workflows/ci.yml) | Push to `main` by a human · manual dispatch | Lint · audit · build bottle · publish to GitHub Release for manually edited formulas |
| [`pr.yml`](.github/workflows/pr.yml) | Pull request to `main` | RuboCop lint · `brew audit --strict` · `brew style` · install from source · `brew test` |

**Automated path (`snapshot.yml`):** runs end-to-end without any PRs or human steps. It detects new upstream releases, updates the formula, computes the SHA256, builds the bottle, publishes it to a GitHub Release, then creates a versioned tap snapshot. Bot commits carry `[skip ci]` so `ci.yml` does not double-build.

**Manual edit path (`ci.yml`):** if you edit a formula by hand and push directly to `main`, `ci.yml` picks it up and builds the bottle. The same job runs on `workflow_dispatch` for force-rebuilds.

Bottles built by `snapshot.yml` are stored as assets under the snapshot release (e.g. `tap-2026-04-21`). Bottles built by `ci.yml` for manual edits go into a per-formula release (e.g. `browserctl-0.3.1`). Neither is committed to the repository — the `bottles/` directory is git-ignored.

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

4. Open a PR — `pr.yml` runs lint, audit, and install automatically.
5. Merge the PR — `ci.yml` builds the bottle, publishes it to a GitHub Release, and commits the updated `bottle do` block back to the formula.

## Updating an existing formula

Formulas are checked and updated automatically by [`snapshot.yml`](.github/workflows/snapshot.yml), which runs weekly (Sunday 23:00 UTC). To trigger an out-of-band update immediately:

1. Go to **Actions → Snapshot → Run workflow**.

The snapshot workflow updates every formula that has a new upstream release, builds bottles, publishes per-formula releases, and tags a timestamped tap snapshot — all in one run, no PR required.

## Formula conventions

- Use `uses_from_macos "ruby", since: :catalina` for tools that work with the system Ruby (2.6+).
- Use `depends_on "ruby"` when the tool requires Ruby ≥ 3.x.
- For gem-based tools, list all runtime dependencies as `resource` blocks with pinned SHA256s taken from the project's `Gemfile.lock` CHECKSUMS section.
- Install gems to `libexec` using `r.stage { system "gem", "install", ... }` and expose binaries via `write_env_script` with `GEM_HOME`/`GEM_PATH` set to `libexec`.
- For platform-specific gems (e.g. nokogiri precompiled), nest `on_arm`/`on_intel` inside a single `resource` block and place it before other resource blocks.
- Order formula sections: `desc`, `homepage`, `url`, `sha256`, `license`, dependencies, resources, `def install`, `def caveats`, `test`.
- Do not commit anything to `bottles/` — it is git-ignored. Bottles live in GitHub Releases.

## Local dev setup

```bash
bundle install   # installs rubocop for linting
```
