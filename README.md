# Patrick's Homebrew Tap

Homebrew formulas for patrick204nqh's open source projects.

## Installation

```bash
brew tap patrick204nqh/tap
```

## Available formulas

| Formula | Description |
|---------|-------------|
| [sumologic-query](Formula/sumologic-query.rb) | Lightweight Ruby CLI for querying Sumo Logic logs and managing collectors |
| [browserctl](Formula/browserctl.rb) | Persistent browser automation daemon and CLI for AI agents |

### sumologic-query

```bash
brew install patrick204nqh/tap/sumologic-query
```

Requires environment variables:

```bash
export SUMO_ACCESS_ID='your_access_id'
export SUMO_ACCESS_KEY='your_access_key'
export SUMO_DEPLOYMENT='us2'  # us1, us2 (default), eu, au
```

### browserctl

```bash
brew install patrick204nqh/tap/browserctl
```

Requires Google Chrome or Chromium. Start the daemon, then use the CLI:

```bash
# Start the browser daemon
browserd &

# Open a page and interact
browserctl page open main --url https://example.com
browserctl snapshot main
browserctl fill main --ref e1 --value "hello"
browserctl click main --ref e2

# Stop the daemon
browserctl daemon stop
```

If you use asdf and previously installed browserctl via RubyGems, asdf
shims for `browserd`/`browserctl` may shadow this Homebrew installation.
Fix it by removing the gem from your asdf-managed Ruby:

```bash
gem uninstall browserctl
asdf reshim ruby
```

Alternatively, ensure Homebrew's bin appears before asdf shims in `PATH`
(add this before your asdf init line in `~/.zshrc` or `~/.bashrc`):

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add or update a formula.
