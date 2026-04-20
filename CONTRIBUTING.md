# Contributing

## Adding a new formula

1. Create `Formula/<tool-name>.rb` following the existing formula conventions.
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

4. Open a PR — CI will run audit, style, and lint automatically.

## Updating an existing formula

Formulas are checked weekly (Monday 9 AM UTC) and auto-updated via the [Update Formulas](.github/workflows/update-formulas.yml) workflow. To trigger an out-of-band update manually:

1. Go to **Actions → Update Formulas → Run workflow**.
2. Optionally specify a formula name, version, and SHA256 to fast-track a specific release.

## Formula conventions

- Use `uses_from_macos "ruby", since: :catalina` for tools that work with the system Ruby (2.6+).
- Use `depends_on "ruby"` when the tool requires Ruby ≥ 3.x.
- For gem-based tools, list all runtime dependencies as `resource` blocks with pinned SHA256s taken from the project's `Gemfile.lock` CHECKSUMS section.
- For platform-specific gems (e.g. nokogiri precompiled), nest `on_arm`/`on_intel` inside a single `resource` block and place it before other resource blocks.
- Order formula sections: `desc`, `homepage`, `url`, `sha256`, `license`, dependencies, resources, `def install`, `def caveats`, `test`.

## Local dev setup

```bash
bundle install   # installs rubocop for linting
```
