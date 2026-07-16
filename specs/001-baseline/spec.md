# Feature Specification: CodeReviewGuardian baseline (100% code coverage)

**Feature Branch**: `001-baseline`  
**Status**: Active  

**Package**: `nowo-tech/code-review-guardian`  
**Code inventory**: [`code-inventory.md`](code-inventory.md)

---

## Summary

Composer **plugin** that installs **code review guardian** shell scripts and config into PHP projects (Symfony, Laravel, etc.) for Git-provider PR review automation. Runtime review logic lives in shipped `bin/` scripts; `src/` holds the plugin installer and framework detection.

---

## User Scenarios

### US-01 — Script installation (P1)

**Given** plugin in `composer.json`, **When** install/update scripts run, **Then** `Plugin` copies `bin/code-review-guardian.sh` and helpers into the project vendor path or configured target.

### US-02 — Framework detection (P2)

**Given** a project root, **When** guardian config is generated, **Then** `FrameworkDetector` selects appropriate defaults for the detected stack.

---

## Requirements

### Plugin (`src/`)

- **FR-PLUGIN-001**: `Plugin` — Composer lifecycle, file copy, chmod, event subscription.
- **FR-DET-001**: `FrameworkDetector` — detect Symfony/Laravel/generic PHP from composer packages and paths.

### Shipped scripts (documented, outside `src/` inventory)

- Review orchestration via `bin/main.sh`, `bin/review.sh`, `bin/comments.sh` (integrator-facing; not counted in Spec Kit `src/` inventory per REQ-SPECKIT-001).

---

## Success Criteria

- **SC-001**: **2/2** `src/` files mapped.
- **SC-002**: Install path documented in README.

---

## Explicit non-goals

- Hosting CI runners (integrator responsibility).
- Symfony bundle DI integration.

---

## Validation

PHPUnit for `FrameworkDetector`, manual install smoke test, inventory audit.
