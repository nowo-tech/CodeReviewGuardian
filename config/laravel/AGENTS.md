# Code Review Rules (PHP 8.4 / Laravel 11)

## PHP General
- Use `declare(strict_types=1);` in new PHP files where applicable.
- Follow PSR-12 and Laravel coding standards.
- Avoid dynamic properties; type everything (props, params, returns).
- Prefer early returns; avoid deep nesting.
- No suppressed errors, no `@` operator.

## Laravel
- Controllers must be thin: delegate to Services/Jobs/Repositories.
- Use Form Requests for validation; do not trust request payloads.
- Use DTOs/Value Objects where appropriate; avoid passing Request deep.
- Use Queues for async/long tasks (no heavy work in controllers).
- Use Service Providers for dependency injection configuration.

## Eloquent / Persistence
- No N+1 queries in loops; use eager loading (`with()`, `load()`).
- Avoid heavy logic in Models; use Services/Repositories.
- Use Database Transactions for multi-write consistency.
- Use Query Scopes for reusable query logic.

## Blade
- No business logic in Blade; only presentation.
- Escape output by default; use `{!! !!}` only when necessary.
- Use Components for reusable UI elements.

## Security
- Never concatenate SQL; always use Eloquent/Query Builder with bindings.
- Ensure CSRF protection on forms (Laravel handles this automatically).
- Validate authorization (Policies/Gates) for write operations.
- Use `bcrypt()` or `Hash::make()` for passwords (never plain text).

## Testing
- New behavior should include tests (Feature/Unit) when reasonable.
- Use Factories for test data creation.
- Prefer Feature tests over Unit tests for HTTP interactions.

