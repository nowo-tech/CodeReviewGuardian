# Code inventory — 100% traceability

**Baseline spec**: [`spec.md`](spec.md)  
**Package**: `nowo-tech/code-review-guardian`  
**Last audited**: 2026-07-07

## Plugin (`src/`)

| Source file | Spec section | Requirement IDs |
| --- | --- | --- |
| `Plugin.php` | Composer install/copy | FR-PLUGIN-001 |
| `FrameworkDetector.php` | Stack detection | FR-DET-001 |

## Coverage summary

| Category | Files | Mapped |
| --- | ---: | ---: |
| Plugin (`src/`) | 2 | 2 |
| **Total production sources** | **2** | **2** |

**Note:** Review shell scripts under `bin/` are part of the Packagist deliverable but outside the Spec Kit `src/` inventory scope (REQ-SPECKIT-001). See [`spec.md`](spec.md) § Shipped scripts.
