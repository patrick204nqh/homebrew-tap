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

```mermaid
flowchart TD
    T([cron Sun 23:00 UTC / workflow_dispatch])

    DETECT[Detect Updates\ncheck upstream GitHub releases\nvs current formula versions]
    OPEN_PR[Open Update PR\nupdate version + sha256\nopen PR on sync/formula-updates-YYYY-MM-DD]
    SKIP([skip — all formulas up to date])

    T --> DETECT
    DETECT -->|updates found| OPEN_PR
    DETECT -->|nothing to update| SKIP

    OPEN_PR -.->|CI runs automatically| CI[ci.yml\nbuild + verify bottles]
    CI -.->|PR merged| RELEASE[release.yml\npublish bottles]

    style DETECT   fill:#dbeafe,stroke:#93c5fd
    style OPEN_PR  fill:#fef9c3,stroke:#fde047
    style SKIP     fill:#f3f4f6,stroke:#d1d5db
    style CI       fill:#dcfce7,stroke:#86efac
    style RELEASE  fill:#dcfce7,stroke:#86efac
```

---

## 4. Build Ruby Runtime — Manual (`build-ruby-runtime.yml`)

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

    PR -.->|CI runs automatically| CI[ci.yml\nbuild + verify bottles]
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
