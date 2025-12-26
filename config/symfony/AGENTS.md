# Code Review Rules (PHP 8.4 / Symfony 7.4)

## PHP General
- Use `declare(strict_types=1);` in new PHP files where applicable.
- Follow PSR-12 and Symfony coding standards.
- Avoid dynamic properties; type everything (props, params, returns).
- Prefer early returns; avoid deep nesting.
- No suppressed errors, no `@` operator.

## Symfony
- Controllers must be thin: delegate to Application/Domain services.
- Use Symfony Validator for input; do not trust request payloads.
- Use ParamConverters/DTOs where appropriate; avoid passing Request deep.
- Use Messenger for async/long tasks (no heavy work in controllers).

## Security
- Never concatenate SQL; always use parameters.
- Ensure CSRF protection on forms/actions where needed.
- Validate authorization (voters/roles) for write operations.

## Doctrine / Persistence
- No N+1 queries in loops; use joins or dedicated queries.
- Avoid heavy logic in entities; keep entities cohesive.
- Transactions where multi-write consistency is required.

## Twig
- No business logic in Twig; only presentation.
- Escape output by default; be careful with `|raw`.

## Testing
- New behavior should include tests (unit/functional) when reasonable.

