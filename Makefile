# Code Review Guardian — root Makefile (Docker workflow)

# Prefer Compose V2 plugin (GitHub Actions / modern Docker Desktop); fall back to docker-compose V1 (REQ-MAKE-010).
COMPOSE ?= $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")
SERVICE_PHP ?= php

.PHONY: help ensure-up up down down-dev build shell install assets test test-coverage \
	check-no-cursor-coauthor check-open-prs strip-cursor-coauthor-from-history \
	cs-check cs-fix rector rector-dry phpstan igor qa release-check composer-sync \
	clean update validate setup-hooks

help:
	@echo "Code Review Guardian - make targets"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Container:"
	@echo "  up                Start Docker container"
	@echo "  down              Stop Docker container"
	@echo "  build             Rebuild Docker image (no cache)"
	@echo "  shell             Open shell in container"
	@echo ""
	@echo "Dependencies:"
	@echo "  install           Install Composer dependencies"
	@echo ""
	@echo "Assets:"
	@echo "  assets            No-op (no frontend assets)"
	@echo ""
	@echo "Tests:"
	@echo "  test              Run PHPUnit tests"
	@echo "  test-coverage     Run tests with coverage (prints the PHP percentage)"
	@echo ""
	@echo "Quality:"
	@echo "  cs-check          Check code style"
	@echo "  cs-fix            Fix code style"
	@echo "  rector            Apply Rector refactoring"
	@echo "  rector-dry        Run Rector in dry-run mode"
	@echo "  phpstan           Run PHPStan static analysis"
	@echo "  igor              Run Igor worker-state audit (REQ-CS-008)"
	@echo "  qa                Run cs-check and tests"
	@echo ""
	@echo "Release:"
	@echo "  release-check     Pre-release chain (REQ-MAKE-002)"
	@echo "  composer-sync     Validate composer.json and align dependencies"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean             Remove vendor, caches and coverage reports"
	@echo ""
	@echo "Composer:"
	@echo "  update            Update dependencies (composer update)"
	@echo "  update-deps       Update dependencies via the monorepo helper (REQ-MAKE-008)"
	@echo "  validate          Validate composer.json (--strict)"
	@echo ""
	@echo "Package-specific:"
	@echo "  check-no-cursor-coauthor  Fail on Cursor co-author trailers (REQ-GIT-001)"
	@echo "  check-open-prs    Fail if unresolved open GitHub PRs remain (REQ-REL-003)"
	@echo "  setup-hooks       Install git hooks (.githooks)"
	@echo "  down-dev          Stop root container (non-destructive)"
	@echo "  ensure-up         Start the container and install dependencies when missing"

ensure-up:
	@echo "Ensuring Docker environment is up..."
	@$(COMPOSE) up -d --build
	@sleep 10
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer install --no-interaction

up:
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

# Stop containers without removing volumes (REQ-MAKE-007)
down-dev:
	@$(COMPOSE) down --remove-orphans

build:
	@$(COMPOSE) build --no-cache

shell: ensure-up
	@$(COMPOSE) exec $(SERVICE_PHP) sh

install: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer install --no-interaction

assets:
	@echo "No frontend assets in this bundle."

test: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer test

test-coverage: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer test-coverage | tee coverage-php.txt
	@./.scripts/php-coverage-percent.sh coverage-php.txt

cs-check: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer cs-check

cs-fix: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer cs-fix

rector: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer rector

rector-dry: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer rector-dry

phpstan: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer phpstan

qa: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer qa

composer-sync: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer validate --strict
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer install --no-interaction


# Run Igor worker-state audit (REQ-CS-008)
# Run Igor worker-state audit (REQ-CS-008)
igor: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer igor

check-open-prs:
	@bash .scripts/check-open-prs.sh

# REQ-MAKE-002 order (no Twig, no demos in this Composer plugin).
release-check:
	@$(MAKE) ensure-up
	@$(MAKE) check-no-cursor-coauthor
	@$(MAKE) check-open-prs
	@$(MAKE) composer-sync
	@$(MAKE) cs-fix
	@$(MAKE) cs-check
	@$(MAKE) rector-dry
	@$(MAKE) phpstan
	@$(MAKE) igor
	@$(MAKE) test-coverage

clean:
	rm -rf vendor
	rm -rf .phpunit.cache
	rm -rf coverage
	rm -f coverage.xml
	rm -f coverage-php.txt
	rm -f .php-cs-fixer.cache

update: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer update

validate: ensure-up
	@$(COMPOSE) exec -T $(SERVICE_PHP) composer validate --strict

check-no-cursor-coauthor:
	@chmod +x .scripts/check-no-cursor-coauthor.sh
	@./.scripts/check-no-cursor-coauthor.sh HEAD

setup-hooks:
	@chmod +x .githooks/pre-commit 2>/dev/null || true
	@chmod +x .githooks/commit-msg 2>/dev/null || true
	@git config core.hooksPath .githooks
	@echo "✅ Git hooks installed (.githooks — includes commit-msg for REQ-GIT-001)."


# REQ-MAKE-008: update-deps (REQ-MAKE-008)
BUNDLE_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
# Optional: monorepo helper absent on standalone GitHub Actions checkout (REQ-MAKE-009).
-include $(BUNDLE_ROOT)/../.scripts/Makefile.update-deps.mk

strip-cursor-coauthor-from-history:
	@chmod +x .scripts/strip-cursor-coauthor-from-history.sh
	@./.scripts/strip-cursor-coauthor-from-history.sh main
