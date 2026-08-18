# Code Review Guardian — root Makefile (Docker workflow)

# Prefer Compose V2 plugin (GitHub Actions / modern Docker Desktop); fall back to docker-compose V1 (REQ-MAKE-010).
COMPOSE ?= $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")
SERVICE_PHP ?= php

.PHONY: help ensure-up up down down-dev build shell install assets test test-coverage \
	check-no-cursor-coauthor strip-cursor-coauthor-from-history \
	cs-check cs-fix rector rector-dry phpstan qa release-check composer-sync \
	clean update validate setup-hooks

help:
	@echo "Code Review Guardian — make targets"
	@echo ""
	@echo "Container: up, down, down-dev, build, shell"
	@echo "Dependencies: install"
	@echo "Assets: assets (no-op)"
	@echo "Tests: test, test-coverage"
	@echo "Quality: cs-check, cs-fix, rector, rector-dry, phpstan, qa"
	@echo "Release: release-check, composer-sync"
	@echo "Cleanup: clean"
	@echo "Composer: update, validate"
	@echo "Other: setup-hooks, ensure-up"

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

release-check: check-no-cursor-coauthor
	@$(MAKE) ensure-up
	@$(MAKE) composer-sync
	@$(MAKE) cs-fix
	@$(MAKE) cs-check
	@$(MAKE) rector-dry
	@$(MAKE) phpstan
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
