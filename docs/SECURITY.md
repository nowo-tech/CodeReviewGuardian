# Security — Code Review Guardian

## Scope

Code Review Guardian is a **development-time** Composer package. It installs scripts and configuration under the consuming project to run code review workflows (including optional integration with AI providers). It does **not** expose HTTP endpoints by itself in the library package.

## Attack surface

- **Configuration files** (`code-review-guardian.yaml`, paths under `docs/` copied to the project): YAML/JSON parsed by the tool; malicious content could influence which commands run if a user is tricked into pasting untrusted config.
- **Shell / process execution**: The guardian invokes external processes (review scripts, optional AI CLIs). Paths and arguments must come from trusted configuration controlled by the repository owner.
- **Third-party APIs** (optional): When AI or Git providers are configured, API keys must be supplied via environment or secure config **outside** version control.

## Threats and mitigations

| Threat | Mitigation |
|--------|------------|
| Arbitrary command execution via crafted config | Users must only use configuration from trusted sources; review YAML before commit; do not merge untrusted templates into CI without review. |
| Secret leakage in logs or config | Never commit API keys; use env vars; see **No-secret logging** below. |
| Dependency confusion | Pin versions; run `composer audit` in CI and before release. |

## Secrets and cryptography

- **No secrets** belong in this repository or in committed consumer config examples.
- API keys for AI or Git hosting must use environment variables or secret stores, not literals in YAML committed to Git.

## Logging

- Verbose modes may print paths and command lines. Avoid logging tokens, webhook secrets, or full API responses containing credentials.

## Dependencies

- Run `composer audit` regularly.
- Keep `composer.json` constraints updated for security patches.

## Permissions and exposure

- The tool runs with the privileges of the developer or CI job. Restrict CI secrets to least privilege (read-only tokens where possible).

## Reporting a vulnerability

Report security issues **privately** (do not open a public issue with exploit details). Contact the maintainers via the email in `composer.json` or the repository security policy.

## Release security checklist (12.4.1)

Before tagging a release, confirm:

| Item | Notes |
|------|--------|
| **SECURITY.md** | This document is current. |
| **`.gitignore` and `.env`** | `.env` and local secrets files are ignored; no secrets committed. |
| **No secrets in repo** | No API keys, tokens, or passwords in tracked files. |
| **Recipe / installer** | Installer copies only intended templates; no default secrets. |
| **Input / output** | Config and CLI inputs validated where applicable; no unsafe `eval` of untrusted input. |
| **Dependencies** | `composer audit` clean or issues triaged. |
| **Logging** | No secrets in default log output. |
| **Cryptography** | N/A unless added; keys never hardcoded. |
| **Permissions / exposure** | Documented who runs the tool (dev/CI). |
| **Limits / DoS** | N/A for CLI; CI timeouts configured in workflows. |

Record confirmation in the release PR or tag notes.
