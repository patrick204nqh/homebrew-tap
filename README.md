# Patrick's Homebrew Tap

Homebrew formulas for patrick204nqh's open source projects.

## Installation

```bash
brew tap patrick204nqh/tap
```

## Available formulas

| Formula | Description |
|---------|-------------|
| [textus](Formula/textus.rb) | Durable multi-writer project memory for humans, AI, and automation |
| [browserctl](Formula/browserctl.rb) | Persistent browser automation daemon and CLI for AI agents |
| [sumologic-query](Formula/sumologic-query.rb) | Lightweight Ruby CLI for querying Sumo Logic logs and managing collectors |

Once tapped, install any formula by name:

```bash
brew install textus   # or browserctl, sumologic-query
```

To install several at once (brace expansion in bash/zsh):

```bash
brew install patrick204nqh/tap/{textus,browserctl,sumologic-query}
```

For usage, configuration, and troubleshooting, see each project's own repository.

## Staying up to date

Formulas are kept in sync with their upstream releases automatically. To pull the
latest versions onto your machine:

```bash
brew update              # refresh tap + formula definitions
brew upgrade             # upgrade all outdated formulas, including this tap's
```

To upgrade just one formula:

```bash
brew upgrade textus
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add or update a formula.
