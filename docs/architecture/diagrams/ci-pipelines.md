# CI Pipeline Diagrams

## 1. Build Bottles — Push to Main

```mermaid
flowchart TD
    T([push: main Formula/** / workflow_dispatch])

    VALIDATE[validate\nlint · detect · audit\nreusable workflow]
    PREPARE[prepare\ncompute tap-YYYY-MM-DD tag]
    RELEASE[release\ncalls release-bottles.yml]
    SKIP([skip])

    T --> VALIDATE
    VALIDATE -->|formulas changed, not bot| PREPARE
    VALIDATE -->|nothing changed| SKIP
    PREPARE --> RELEASE

    style VALIDATE fill:#dbeafe,stroke:#93c5fd
    style PREPARE  fill:#dbeafe,stroke:#93c5fd
    style RELEASE  fill:#dcfce7,stroke:#86efac
    style SKIP     fill:#f3f4f6,stroke:#d1d5db
```

## 2. Validate PR — Pull Request

```mermaid
flowchart TD
    T([pull_request → main])

    VALIDATE[validate\nlint · detect · audit\nreusable workflow]
    INSTALL[install\nmatrix per formula]
    SKIP([skip])

    T --> VALIDATE
    VALIDATE -->|formulas changed| INSTALL
    VALIDATE -->|nothing changed| SKIP

    style VALIDATE fill:#dbeafe,stroke:#93c5fd
    style INSTALL  fill:#dcfce7,stroke:#86efac
    style SKIP     fill:#f3f4f6,stroke:#d1d5db
```

## 3. Sync Formulas — Weekly

```mermaid
flowchart TD
    T([cron Sun 23:00 UTC / workflow_dispatch])

    DETECT[detect\ncheck upstream versions\noutput formula_names + snapshot_tag]
    UPDATE[update-formulas\nbatch version + sha256 updates\nsingle commit to main]
    RELEASE[release\ncalls release-bottles.yml]
    SKIP([skip])

    T --> DETECT
    DETECT -->|updates found| UPDATE
    DETECT -->|nothing to update| SKIP
    UPDATE --> RELEASE

    style DETECT  fill:#dbeafe,stroke:#93c5fd
    style UPDATE  fill:#dbeafe,stroke:#93c5fd
    style RELEASE fill:#dcfce7,stroke:#86efac
    style SKIP    fill:#f3f4f6,stroke:#d1d5db
```

## 4. Release Bottles — Reusable

_Called by Build Bottles and Sync Formulas._

```mermaid
flowchart TD
    IN([inputs: formulas · snapshot_tag])

    PREPARE[prepare\ncreate draft tap-YYYY-MM-DD release]
    BUILD[build\nmatrix per formula\ninstall · bottle · merge · upload]
    FINALIZE[finalize\npublish release with formula versions]
    SMOKE[smoke-test\nmatrix per formula\nbrew tap · brew install · poured_from_bottle · brew test]

    IN --> PREPARE --> BUILD --> FINALIZE --> SMOKE

    style PREPARE  fill:#dbeafe,stroke:#93c5fd
    style BUILD    fill:#dcfce7,stroke:#86efac
    style FINALIZE fill:#dbeafe,stroke:#93c5fd
    style SMOKE    fill:#fef9c3,stroke:#fde047
```

## 5. Build Ruby Runtime — Manual

```mermaid
flowchart TD
    T([workflow_dispatch\nruby_version input])

    VALIDATE[validate\ninput format X.Y.Z]
    BUILD[build\nruby-build VERSION]
    PATCH[patch\nrbconfig relocatable]
    ARCHIVE[archive\ntar + sha256]
    UPLOAD[upload\ngh release ruby-runtime-X.Y.Z]
    PR[open PR\nupdate sha256 in all formulas]

    T --> VALIDATE --> BUILD --> PATCH --> ARCHIVE --> UPLOAD --> PR

    style VALIDATE fill:#dbeafe,stroke:#93c5fd
    style BUILD    fill:#dcfce7,stroke:#86efac
    style PATCH    fill:#dcfce7,stroke:#86efac
    style ARCHIVE  fill:#dcfce7,stroke:#86efac
    style UPLOAD   fill:#dcfce7,stroke:#86efac
    style PR       fill:#fef9c3,stroke:#fde047
```
