# CI Pipeline Diagrams

## 1. Pull Request — `validate.yml` + `bottle.yml`

PR checks are split by concern: `validate.yml` runs the human-authored
checks, `bottle.yml` runs the bot-authored build + smoke test. They run
in parallel; both must pass before merge.

```mermaid
flowchart TD
    T([pull_request → main\nopened · synchronize · reopened])

    VALIDATE[validate.yml\nLint · Detect · Audit\nhuman-authored checks]
    BOTTLE[bottle.yml\nBuild / formula — build · upload · commit bottle block\nSmoke Test / formula — install from bottle · brew test]
    BOTTLE_SKIP([bottle.yml skipped — no Formula/** changes])

    T --> VALIDATE
    T -->|Formula/** changed| BOTTLE
    T -->|no Formula/** changes| BOTTLE_SKIP

    style VALIDATE   fill:#dbeafe,stroke:#93c5fd
    style BOTTLE     fill:#dcfce7,stroke:#86efac
    style BOTTLE_SKIP fill:#f3f4f6,stroke:#d1d5db
```

`bottle.yml` short-circuits via a `# bottle-source-digest:` check: it rebuilds
only when the formula's install-relevant content (everything except the bottle
block) has changed. This catches same-version gem-resource updates while the
bot's bottle commit-back still skips re-building on its own push.

When a PR is **closed without merging**, `cleanup.yml` fires and deletes
any prerelease that was created during CI.

---

## 2. Release — Push to Main (`release.yml`)

Triggered when a PR merges. Publishes the prerelease that was already built
and verified during PR CI. No bottle is built here.

```mermaid
flowchart TD
    T([push: main Formula/**])

    DETECT[Detect\nchanged formulas]
    PUBLISH[Publish / formula\nderive tag from formula version\ngraduate prerelease → full release]
    SKIP([skip — no formula changes\nor release already published])

    T --> DETECT
    DETECT -->|formulas changed| PUBLISH
    DETECT -->|nothing changed| SKIP

    style DETECT  fill:#dbeafe,stroke:#93c5fd
    style PUBLISH fill:#dcfce7,stroke:#86efac
    style SKIP    fill:#f3f4f6,stroke:#d1d5db
```

---

## 3. Sync Formulas — Weekly (`sync-formulas.yml`)

One weekly job bumps source versions **and** regenerates gem resources. After
any version bump it runs `gen-formula`, and it also regenerates every formula
unconditionally to catch same-version gem drift. Only real diffs get committed,
so an all-current run opens no PR. (The retired `sync-gems.yml` is folded in
here.)

```mermaid
flowchart TD
    T([cron Sun 23:00 UTC / workflow_dispatch])

    DETECT[Detect Updates\ncheck upstream GitHub releases\nvs current formula versions]
    BUMP[Bump version + sha256\nfor each formula with a newer release]
    REGEN[Regenerate gem resources\ngen-formula rebuilds every formula's\ngem closure from a fresh lockfile]
    DIFF{any diff?}
    OPEN_PR[Open Update PR\nversion + gem-resource changes\nsync/formula-updates-YYYY-MM-DD]
    SKIP([skip — nothing changed])

    T --> DETECT --> BUMP --> REGEN --> DIFF
    DIFF -->|changes| OPEN_PR
    DIFF -->|no changes| SKIP

    OPEN_PR -.->|CI runs automatically| CI[validate.yml + bottle.yml\nlint · audit · build + verify bottles]
    CI -.->|PR merged| RELEASE[release.yml\npublish bottles]

    style DETECT   fill:#dbeafe,stroke:#93c5fd
    style BUMP     fill:#dcfce7,stroke:#86efac
    style REGEN    fill:#dcfce7,stroke:#86efac
    style OPEN_PR  fill:#fef9c3,stroke:#fde047
    style SKIP     fill:#f3f4f6,stroke:#d1d5db
    style CI       fill:#dcfce7,stroke:#86efac
    style RELEASE  fill:#dcfce7,stroke:#86efac
```

---

## 4. Sync Ruby Runtime — Weekly (`sync-ruby-runtime.yml`)

```mermaid
flowchart TD
    T([cron Sun 21:00 UTC / workflow_dispatch])

    READ[Read Current Version\nRUBY_RUNTIME_VERSION from formulas]
    QUERY[Query ruby-build\nlist X.Y.x definitions on GitHub]
    TRIGGER[Trigger build-ruby-runtime.yml\ngh workflow run -f ruby_version=X.Y.Z]
    SKIP([skip — runtime up to date\nor release already exists])

    T --> READ --> QUERY
    QUERY -->|newer patch found\nno release yet| TRIGGER
    QUERY -->|up to date| SKIP
    TRIGGER -.->|builds runtime + opens PR| BUILD[build-ruby-runtime.yml]

    style READ     fill:#dbeafe,stroke:#93c5fd
    style QUERY    fill:#dbeafe,stroke:#93c5fd
    style TRIGGER  fill:#fef9c3,stroke:#fde047
    style SKIP     fill:#f3f4f6,stroke:#d1d5db
    style BUILD    fill:#dcfce7,stroke:#86efac
```

---

## 5. Build Ruby Runtime — Manual / Auto (`build-ruby-runtime.yml`)

```mermaid
flowchart TD
    T([workflow_dispatch\nruby_version input])

    VALIDATE[Validate\ninput format X.Y.Z]
    BUILD[Build\nruby-build VERSION]
    PATCH[Patch\nrbconfig relocatable]
    ARCHIVE[Archive\ntar + sha256]
    UPLOAD[Upload\ngh release ruby-runtime-X.Y.Z]
    PR[Open PR\nupdate sha256 in all formulas]

    T --> VALIDATE --> BUILD --> PATCH --> ARCHIVE --> UPLOAD --> PR

    PR -.->|CI runs automatically| CI[validate.yml + bottle.yml\nlint · audit · build + verify bottles]
    CI -.->|PR merged| RELEASE[release.yml\npublish bottles]

    style VALIDATE fill:#dbeafe,stroke:#93c5fd
    style BUILD    fill:#dcfce7,stroke:#86efac
    style PATCH    fill:#dcfce7,stroke:#86efac
    style ARCHIVE  fill:#dcfce7,stroke:#86efac
    style UPLOAD   fill:#dcfce7,stroke:#86efac
    style PR       fill:#fef9c3,stroke:#fde047
    style CI       fill:#dcfce7,stroke:#86efac
    style RELEASE  fill:#dcfce7,stroke:#86efac
```
