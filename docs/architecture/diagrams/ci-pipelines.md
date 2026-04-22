# CI Pipeline Diagrams

## 1. CI — Push to Main

```mermaid
flowchart TD
    T([push: main / workflow_dispatch])

    LINT[lint]
    DETECT[detect]
    AUDIT[audit]
    BUILD[build-and-publish\nmatrix per formula]
    SKIP([skip])

    T --> LINT & DETECT
    DETECT -->|changed| AUDIT
    DETECT -->|nothing changed| SKIP
    LINT & AUDIT & DETECT -->|changed, not bot| BUILD

    style LINT   fill:#dbeafe,stroke:#93c5fd
    style DETECT fill:#dbeafe,stroke:#93c5fd
    style AUDIT  fill:#dbeafe,stroke:#93c5fd
    style BUILD  fill:#dcfce7,stroke:#86efac
    style SKIP   fill:#f3f4f6,stroke:#d1d5db
```

## 2. PR — Validate Pull Request

```mermaid
flowchart TD
    T([pull_request → main])

    LINT[lint]
    DETECT[detect]
    AUDIT[audit]
    INSTALL[install\nmatrix per formula]
    SKIP([skip])

    T --> LINT & DETECT
    DETECT -->|changed| AUDIT
    DETECT -->|nothing changed| SKIP
    LINT & AUDIT & DETECT -->|changed| INSTALL

    style LINT    fill:#dbeafe,stroke:#93c5fd
    style DETECT  fill:#dbeafe,stroke:#93c5fd
    style AUDIT   fill:#dbeafe,stroke:#93c5fd
    style INSTALL fill:#dcfce7,stroke:#86efac
    style SKIP    fill:#f3f4f6,stroke:#d1d5db
```

## 3. Snapshot — Weekly Auto-Update

```mermaid
flowchart TD
    T([cron Sun 23:00 UTC / workflow_dispatch])

    DETECT[detect\ncheck upstream versions]
    CREATE[create-release\ndraft]
    BUILD[update-and-build\nmatrix per formula]
    TAG[tag-snapshot\npublish]
    SKIP([skip])

    T --> DETECT
    DETECT -->|updates found| CREATE & BUILD
    DETECT -->|nothing to update| SKIP
    CREATE & BUILD --> TAG

    style DETECT fill:#dbeafe,stroke:#93c5fd
    style CREATE fill:#dbeafe,stroke:#93c5fd
    style BUILD  fill:#dcfce7,stroke:#86efac
    style TAG    fill:#dbeafe,stroke:#93c5fd
    style SKIP   fill:#f3f4f6,stroke:#d1d5db
```

## 4. Build Ruby Runtime — Manual

```mermaid
flowchart TD
    T([workflow_dispatch\nruby_version input])

    BUILD[build\nruby-build VERSION]
    PATCH[patch\nrbconfig relocatable]
    ARCHIVE[archive\ntar + sha256]
    UPLOAD[upload\ngh release]

    T --> BUILD --> PATCH --> ARCHIVE --> UPLOAD

    style BUILD   fill:#dcfce7,stroke:#86efac
    style PATCH   fill:#dcfce7,stroke:#86efac
    style ARCHIVE fill:#dcfce7,stroke:#86efac
    style UPLOAD  fill:#dcfce7,stroke:#86efac
```
