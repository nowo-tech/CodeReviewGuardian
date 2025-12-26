# Code Review Agents Configuration

This document explains how to configure AI-powered code review agents for Code Review Guardian.

## Overview

Code Review Guardian supports AI-powered code review agents that can automatically review your pull requests and merge requests. These agents analyze your code for quality, security, and best practices.

## Configuration

### Environment Variables

Add the following environment variables to your `.env` file:

```env
# Git Provider API Token
# Required for posting comments and reviews to PRs/MRs
GIT_TOKEN=your_github_or_gitlab_token_here

# Optional: AI Agent Configuration
# AI_AGENT_PROVIDER=openai|anthropic|github_copilot
# AI_AGENT_MODEL=gpt-4|claude-3|etc
# AI_AGENT_TEMPERATURE=0.7
```

### Getting Your Git Token

For detailed step-by-step instructions on creating accounts and obtaining tokens, see [TOKEN_SETUP.md](TOKEN_SETUP.md).

The quick reference for environment variable format:

```env
# GitHub
GIT_TOKEN=ghp_your_github_token_here

# GitLab
GIT_TOKEN=glpat-your_gitlab_token_here

# Bitbucket
GIT_TOKEN=your_bitbucket_app_password_here
```

## Agent Providers

Code Review Guardian supports multiple AI agent providers:

### GitHub Copilot

GitHub Copilot can be used for code review when running in GitHub Actions:

```yaml
# code-review-guardian.yaml
agents:
  provider: github_copilot
  enabled: true
```

### OpenAI

For OpenAI models (GPT-4, GPT-3.5, etc.):

```yaml
# code-review-guardian.yaml
agents:
  provider: openai
  model: gpt-4
  enabled: true
```

Required environment variable:
```env
OPENAI_API_KEY=your_openai_api_key_here
```

### Anthropic Claude

For Anthropic Claude models:

```yaml
# code-review-guardian.yaml
agents:
  provider: anthropic
  model: claude-3-opus
  enabled: true
```

Required environment variable:
```env
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

## Agent Configuration

Configure agents in your `code-review-guardian.yaml`:

```yaml
agents:
  enabled: true
  provider: openai  # openai, anthropic, github_copilot
  model: gpt-4
  temperature: 0.7
  
  # What the agent should review
  review_scope:
    - code_quality
    - security
    - performance
    - best_practices
    - documentation
  
  # Agent behavior
  behavior:
    suggest_fixes: true
    explain_issues: true
    provide_examples: true
    severity_threshold: medium  # low, medium, high, critical
```

## Usage

Once configured, the agents will automatically review your code when you run:

```bash
./code-review-guardian.sh --agent-review
```

Or integrate into your CI/CD pipeline:

```yaml
# .github/workflows/code-review.yml
- name: Run Code Review Guardian with AI Agents
  env:
    GIT_TOKEN: ${{ secrets.GIT_TOKEN }}
    OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
  run: |
    ./code-review-guardian.sh --agent-review --post-comment
```

## Best Practices

1. **Keep tokens secure**: Never commit tokens to your repository. Use environment variables or secrets.
2. **Review agent suggestions**: AI agents provide suggestions, but always review them before applying.
3. **Configure severity threshold**: Set appropriate severity levels to avoid too many false positives.
4. **Test locally first**: Test agent reviews locally before enabling in CI/CD.

## Troubleshooting

### Agent not working

- Check that `GIT_TOKEN` is set correctly
- Verify API keys are valid (for OpenAI/Anthropic)
- Check agent provider is enabled in configuration

### Too many suggestions

- Increase `severity_threshold` in agent configuration
- Reduce `temperature` for more focused reviews
- Adjust `review_scope` to focus on specific areas

## Additional Resources

- [Configuration Guide](CONFIGURATION.md) - Full Configuration Guide (in Code Review Guardian package)
- [Git Guardian Angel Guide](GGA.md)
- [Code Review Guardian README](https://github.com/nowo-tech/code-review-guardian) - Main Documentation

