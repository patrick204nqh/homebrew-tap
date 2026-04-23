# ADR 001: arm64-only Bottles

Date: 2026-04-23
Status: Accepted

## Context

This tap distributes pre-built Homebrew bottles for Ruby-based CLI tools. Each
tool embeds a relocatable Ruby runtime built by `build-ruby-runtime.yml`. The
runtime is compiled with `ruby-build` on a macOS GitHub Actions runner.

GitHub-hosted macOS runners are arm64 (Apple Silicon M-series) by default.
Building x86_64 bottles requires a separate `macos-13` runner (Intel) and would
double CI time, cost, and release complexity.

The primary users of this tap develop on Apple Silicon. Anyone on Intel can
still install via `brew install` — Homebrew falls back to a source build from
the formula's tarball URL when no matching bottle is available.

## Decision

Build and distribute arm64-only bottles. No Intel runner is added to the
bottle-build or sync-formulas workflows.

## Consequences

**Positive**
- Single-runner CI — faster feedback, lower Actions minutes consumed.
- One bottle file per formula per release — no platform matrix to coordinate.
- No ruby-runtime rebuild needed for Intel architecture.

**Negative / accepted trade-offs**
- Intel users build from source on every install (~5-10 min vs. seconds).
- If a gem dependency requires native compilation (e.g. `websocket-driver`),
  Intel source builds must also compile that gem.

## Revisiting this decision

Add Intel support when either:
- A team member regularly works on Intel hardware and finds source builds
  impractical, or
- The tooling is distributed more broadly and install latency matters.

Steps to add: introduce an `on_intel` block in each formula and add a
`macos-13` runner job in `build-bottles.yml` and `sync-formulas.yml`.
