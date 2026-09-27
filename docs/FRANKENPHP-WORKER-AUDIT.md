# FrankenPHP worker mode audit (kernel not reset between requests)

| Field | Value |
|-------|-------|
| Package | `nowo-tech/code-review-guardian` (`composer-plugin`, marked `"abandoned": true`) |
| Audited revision | `v1.1.5` / `e6ec13c` |
| Audit date | 2026-09-23 |
| Method | Manual review of every file under `src/` (`Plugin.php`, `FrameworkDetector.php`); `bin/*.sh` and `config/*` checked to confirm they are shell scripts / static files copied into the project |
| **Verdict** | — **Not applicable** — Composer plugin that copies a shell script, YAML and Markdown files on `composer install/update`; no Symfony bundle, no container services, nothing runs inside the HTTP worker |

## Execution model assumed

FrankenPHP worker mode boots the Symfony kernel once per worker and serves many requests with the same container. This audit assumes the **strict** variant: the kernel is **not** rebooted between requests, so every shared service, static property and PHP global survives from one request to the next. Two scenarios are evaluated:

- **A — kernel not rebooted, `services_resetter` still runs:** services tagged `kernel.reset` (or implementing `ResetInterface`) are reset between requests.
- **B — no reset at all:** nothing is reset; any per-request state kept in a service leaks into the next request.

A bundle that is safe under **B** is safe under **A** and under classic mode / PHP-FPM.

## Why it does not run in the worker

- `composer.json` declares `"type": "composer-plugin"` with `extra.class = NowoTech\CodeReviewGuardian\Plugin` and only requires `php` and `composer-plugin-api`. There is no `Bundle` class, DI extension, service config, route, listener or Twig extension.
- `src/Plugin.php` is instantiated by Composer. It reacts only to `post-install-cmd` / `post-update-cmd` (`src/Plugin.php:75-103`) and to `uninstall()` (`:65-68`), copying or removing `code-review-guardian.sh`, `code-review-guardian.yaml`, `docs/AGENTS.md`, `docs/GGA.md` and editing `.gitignore`.
- `src/FrameworkDetector.php` is a class with only constants and pure `static` methods, used by the plugin to pick the config directory.
- The actual review logic lives in POSIX shell scripts (`bin/main.sh`, `bin/review.sh`, …) executed by developers or CI, not by PHP.

## Summary

| Area | Status | Notes |
|------|--------|-------|
| Mutable state in shared services | ✅ N/A | No container services. `Plugin::$composer` is set once in `activate()` inside the Composer process |
| Static properties / `static` locals | ✅ | None. `FrameworkDetector` only has constants and pure static methods |
| `ResetInterface` / `kernel.reset` coverage | ✅ N/A | Nothing to reset |
| Request / user / locale captured in services | ✅ N/A | No HTTP code |
| Superglobals, `$_ENV`, `putenv`, `ini_set`, `setlocale`, timezone | ✅ | None used |
| Doctrine / EntityManager | ✅ N/A | No persistence |
| Output, headers, `exit`, shutdown functions | ✅ N/A | Output goes through Composer's `IOInterface` |
| Resources (files, sockets, cURL) held open | ✅ N/A | One-shot `copy()`, `chmod()`, `unlink()`, `file_put_contents()` during Composer runs |
| Memory growth across requests | ✅ N/A | Short-lived Composer process |
| Blocking I/O and timeouts | ✅ N/A | Local filesystem only |
| Third-party static state | ✅ N/A | Only Composer plugin API |
| PHPStan FrankenPHP rulesets | ✅ | `extension.neon`, `ruleset-classic.neon` and `ruleset-worker.neon` included in `phpstan.neon.dist` |

Worker demo: none (no `demo/` directory; expected for a Composer plugin).

## Services reviewed

| Service | Shared | Mutable state | Scenario A | Scenario B |
|---------|--------|---------------|------------|------------|
| — (no Symfony services) | — | — | N/A | N/A |
| `NowoTech\CodeReviewGuardian\Plugin` (Composer plugin, not a Symfony service) | Composer process only | `$composer` set in `activate()` | N/A | N/A |
| `NowoTech\CodeReviewGuardian\FrameworkDetector` (static helper) | — | none | N/A | N/A |

## Findings

No worker-mode findings: the package never executes inside the HTTP worker.

### W-01 — Package is abandoned (Info)

- **Where:** `composer.json:6` (`"abandoned": true`) and the notice at the top of `README.md`.
- **Worker impact:** none. It is only relevant for maintenance: the files it installs (`code-review-guardian.sh`, YAML, Markdown) are development tooling.
- **Recommendation:** keep it in `require-dev` only (or remove it), so it is not shipped in production images.

## Usage recommendations in worker mode

- Install it as a development dependency; it has no effect on FrankenPHP workers.
- Do not reference `Plugin` or `FrameworkDetector` from application code.
- Keep `code-review-guardian.sh` / `code-review-guardian.yaml` out of the web root (the plugin writes them to the project root, not to `public/`).

## Re-audit triggers

Re-run this audit if the package gains a Symfony bundle class, a DI extension, PHP classes meant to be called from web code, or any code autoloaded and executed during HTTP requests.
