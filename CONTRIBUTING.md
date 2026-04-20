# Contributing

## CI strategy

Two workflows handle all automation:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`pr.yml`](.github/workflows/pr.yml) | Pull request to `main` | RuboCop lint · `brew audit --strict` · `brew style` · install from source · `brew test` |
| [`ci.yml`](.github/workflows/ci.yml) | Push to `main` | Same checks, then build bottle · publish to GitHub Release · delete stale releases · commit updated bottle block back to formula |

PRs never build or publish bottles. Bottles are always built from the merged result on `main`.

After a successful main push, CI auto-commits a `bottles: <formula> v<version> [skip ci]` commit that updates the `bottle do` block in the formula with the new SHA256 and rebuild number. No manual step required.

Bottles are stored as [GitHub Release](https://github.com/patrick204nqh/homebrew-tap/releases) assets — not in the repository. The `bottles/` directory is git-ignored.

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

Formulas are checked weekly (Monday 9 AM UTC) and auto-updated via the [Update Formulas](.github/workflows/update-formulas.yml) workflow. To trigger an out-of-band update manually:

1. Go to **Actions → Update Formulas → Run workflow**.
2. Optionally specify a formula name, version, and SHA256 to fast-track a specific release.

The update workflow opens a PR bumping the version and SHA256. Merging that PR triggers `ci.yml` to rebuild the bottle.

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
