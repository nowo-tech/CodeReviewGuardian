# Code Review Rules (PHP 8.4)

## PHP General
- Use `declare(strict_types=1);` in new PHP files where applicable.
- Follow PSR-12 coding standards.
- Avoid dynamic properties; type everything (props, params, returns).
- Prefer early returns; avoid deep nesting.
- No suppressed errors, no `@` operator.
- Use type hints for all function parameters and return types.

## Architecture
- Separate concerns: Controllers, Services, Repositories.
- Use dependency injection; avoid global state.
- Keep classes focused and cohesive (Single Responsibility Principle).

## Security
- Never concatenate SQL; always use prepared statements with parameters.
- Validate and sanitize all user input.
- Use strong password hashing (password_hash with PASSWORD_BCRYPT or PASSWORD_ARGON2ID).
- Implement CSRF protection where applicable.
- Validate authorization for all write operations.

## Database / Persistence
- No N+1 queries in loops; use joins or batch loading.
- Use transactions for multi-step database operations.
- Avoid SQL injection; always use parameterized queries.
- Index frequently queried columns.

## Testing
- New behavior should include tests when reasonable.
- Use dependency injection for testability.
- Mock external dependencies in tests.

