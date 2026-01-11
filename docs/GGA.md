# Git Guardian Angel (GGA) Configuration

Git Guardian Angel (GGA) is an intelligent code review system that works seamlessly with Code Review Guardian to provide automated code reviews across different Git providers.

## What is Git Guardian Angel?

Git Guardian Angel is a provider-agnostic system that:
- ✅ Works with GitHub, GitLab, Bitbucket, and any Git provider
- ✅ Automatically reviews code in pull requests and merge requests
- ✅ Provides actionable feedback and suggestions
- ✅ Integrates with your existing CI/CD pipeline
- ✅ Supports multiple AI agents for code review

## Quick Start

### 1. Install Code Review Guardian

```bash
composer require --dev nowo-tech/code-review-guardian
```

### 2. Configure Git Token

Add your Git provider token to `.env`:

```env
# Required: Git Provider API Token
GIT_TOKEN=your_token_here
```

See [TOKEN_SETUP.md](TOKEN_SETUP.md) for detailed step-by-step instructions on creating accounts and obtaining tokens for each provider.

### 3. Configure Code Review Guardian

The configuration file `code-review-guardian.yaml` is automatically installed. Update it to enable Git Guardian Angel:

```yaml
# code-review-guardian.yaml
git:
  provider: auto  # auto-detects GitHub, GitLab, or Bitbucket
  api_token_env: GIT_TOKEN  # Reads from .env file
  repository_url: auto  # auto-detected from git remote

# Enable Git Guardian Angel
gga:
  enabled: true
  auto_review: true  # Automatically review new PRs/MRs
  post_comments: true  # Post review comments
  
agents:
  enabled: true
  provider: openai  # or anthropic, github_copilot
```

### 4. Run in CI/CD

Add to your CI/CD pipeline (GitHub Actions example):

```yaml
# .github/workflows/code-review.yml
name: Code Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          
      - name: Install dependencies
        run: composer install
        
      - name: Run Code Review Guardian
        env:
          GIT_TOKEN: ${{ secrets.GIT_TOKEN }}
        run: |
          ./code-review-guardian.sh --post-comment
```

## Configuration Options

### Git Provider Settings

```yaml
git:
  # Provider: auto, github, gitlab, bitbucket
  provider: auto
  
  # Environment variable name that contains the API token
  api_token_env: GIT_TOKEN
  
  # Repository URL (auto-detected if set to 'auto')
  repository_url: auto
```

### Git Guardian Angel Settings

```yaml
gga:
  # Enable/disable Git Guardian Angel
  enabled: true
  
  # Automatically review new PRs/MRs
  auto_review: true
  
  # Post review comments to PRs/MRs
  post_comments: true
  
  # Review only changed files
  review_changed_files_only: true
  
  # Maximum number of comments per review
  max_comments: 50
  
  # AI Provider for GGA (codex, claude, gemini, ollama)
  provider: codex
  
  # File patterns to review
  file_patterns:
    - "*.php"
    - "*.twig"  # Symfony uses Twig, Laravel uses *.blade.php
  
  # Patterns to exclude from review
  exclude_patterns:
    - "vendor/*"
    - "var/*"  # Symfony: var/, Laravel: storage/
    - "public/build/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  
  # Rules file (relative to project root)
  rules_file: "docs/AGENTS.md"
  
  # Strict mode: fail if response is ambiguous
  strict_mode: true
```

### Agent Configuration

See [AGENTS_CONFIG.md](AGENTS_CONFIG.md) for detailed agent configuration.

## Provider-Specific Setup

### GitHub

1. **Create Personal Access Token**:
   - Go to Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate token with `repo` and `pull_requests` scopes

2. **Add to GitHub Secrets** (for CI/CD):
   - Go to repository Settings → Secrets and variables → Actions
   - Add secret `GIT_TOKEN` with your token

3. **Local `.env` file** (recommended for local development):
   ```env
   GIT_TOKEN=ghp_your_token_here
   ```
   
   **Note**: The script supports `.env` and `.env.local` files. `.env.local` takes priority over `.env`. If the `.env` file doesn't exist, it will be created automatically with a template.

### GitLab

1. **Create Access Token**:
   - Go to Settings → Access Tokens
   - Create token with `api` and `write_repository` scopes

2. **Add to GitLab CI/CD Variables**:
   - Go to Settings → CI/CD → Variables
   - Add variable `GIT_TOKEN` with your token (masked)

3. **Local `.env` file**:
   ```env
   GIT_TOKEN=glpat-your_token_here
   ```

### Bitbucket

1. **Create App Password**:
   - Go to Personal settings → App passwords
   - Create password with `Repositories: Write` and `Pull requests: Write` permissions

2. **Add to Bitbucket Pipelines Variables**:
   - Go to Repository settings → Pipelines → Repository variables
   - Add variable `GIT_TOKEN` with your app password

3. **Local `.env` file**:
   ```env
   GIT_TOKEN=your_app_password_here
   ```

## Advanced Configuration

### Framework-Specific File Patterns

The GGA configuration adapts automatically based on your framework. Here are the default patterns for each framework:

#### Symfony

```yaml
gga:
  provider: codex
  file_patterns:
    - "*.php"
    - "*.twig"
  exclude_patterns:
    - "vendor/*"
    - "var/*"
    - "public/build/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  rules_file: "docs/AGENTS.md"
  strict_mode: true
```

#### Laravel

```yaml
gga:
  provider: codex
  file_patterns:
    - "*.php"
    - "*.blade.php"
  exclude_patterns:
    - "vendor/*"
    - "storage/*"
    - "public/build/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  rules_file: "docs/AGENTS.md"
  strict_mode: true
```

#### Generic PHP

```yaml
gga:
  provider: codex
  file_patterns:
    - "*.php"
  exclude_patterns:
    - "vendor/*"
    - "node_modules/*"
    - "*.min.js"
    - "*.map"
  rules_file: "docs/AGENTS.md"
  strict_mode: true
```

### GGA Provider Options

You can configure different AI providers for GGA:

- **codex**: Default provider (recommended)
- **claude**: Anthropic Claude
- **gemini**: Google Gemini
- **ollama**: Local Ollama instance

```yaml
gga:
  provider: claude  # Change to your preferred provider
```

## Integration Examples

### GitHub Actions

```yaml
name: Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          
      - name: Install dependencies
        run: composer install
        
      - name: Run Code Review Guardian
        env:
          GIT_TOKEN: ${{ secrets.GIT_TOKEN }}
        run: |
          ./code-review-guardian.sh --post-comment
```

### GitLab CI

```yaml
# .gitlab-ci.yml
code_review:
  only:
    - merge_requests
  script:
    - composer install
    - ./code-review-guardian.sh --post-comment
  variables:
    GIT_TOKEN: $GIT_TOKEN
```

### Bitbucket Pipelines

```yaml
# bitbucket-pipelines.yml
pipelines:
  pull-requests:
    '**':
      - step:
          name: Code Review
          script:
            - composer install
            - ./code-review-guardian.sh --post-comment
```

## Troubleshooting

### Token not found

- Verify `.env` or `.env.local` file exists and contains `GIT_TOKEN`
- Check token is set correctly (no extra spaces)
- Remember: `.env.local` takes priority over `.env`
- For CI/CD, verify token is in secrets/variables
- If `.env` doesn't exist, the script will create it automatically

### Comments not posting

- Verify token has correct permissions
- Check Git provider API rate limits
- Review logs for API error messages

### Wrong provider detected

- Set `provider` explicitly in configuration instead of `auto`
- Verify git remote URL is correct

## Security Best Practices

1. **Never commit tokens**: Use `.env` file (gitignored) or CI/CD secrets
2. **Use least privilege**: Only grant minimum required permissions
3. **Rotate tokens regularly**: Update tokens periodically
4. **Monitor usage**: Review API usage to detect anomalies

## Additional Resources

- [AGENTS_CONFIG.md](AGENTS_CONFIG.md) - AI Agent Configuration
- [CONFIGURATION.md](CONFIGURATION.md) - Full Configuration Guide (in Code Review Guardian package)
- [Code Review Guardian README](https://github.com/nowo-tech/CodeReviewGuardian) - Main Documentation

