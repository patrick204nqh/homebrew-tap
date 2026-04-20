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
browserd                              # start daemon
browserctl goto https://example.com
browserctl snap                       # AI-friendly DOM snapshot
browserctl shutdown
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add or update a formula.
