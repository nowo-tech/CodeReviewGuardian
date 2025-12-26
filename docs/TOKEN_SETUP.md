# Token Setup Guide

This guide provides step-by-step instructions for creating accounts and obtaining API tokens for different Git providers to use with Code Review Guardian.

## Overview

Code Review Guardian requires a Git provider API token to post review comments to pull requests and merge requests. This token authenticates your requests to the Git provider's API.

**Security Note:** Never commit tokens to your repository. Always use `.env` files (which should be in `.gitignore`) or CI/CD secrets.

## GitHub

### Step 1: Create/Login to GitHub Account

1. Go to [GitHub.com](https://github.com)
2. If you don't have an account, click **Sign up** and follow the registration process
3. If you have an account, click **Sign in** and enter your credentials

### Step 2: Generate Personal Access Token (Classic)

1. Click on your profile picture in the top-right corner
2. Select **Settings**
3. In the left sidebar, scroll down and click **Developer settings**
4. Click **Personal access tokens** → **Tokens (classic)**
5. Click **Generate new token** → **Generate new token (classic)**
6. Give your token a descriptive name (e.g., "Code Review Guardian")
7. Set an expiration date (recommended: 90 days or custom expiration)
8. Select the following scopes/permissions:
   - ✅ **repo** (Full control of private repositories)
     - This includes: repo:status, repo_deployment, public_repo, repo:invite, security_events
   - ✅ **pull_requests** (Read and write access to pull requests)
9. Scroll down and click **Generate token**
10. **IMPORTANT:** Copy the token immediately. It will look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - You won't be able to see it again after leaving the page
   - If you lose it, you'll need to generate a new one

### Step 3: Add Token to Your Project

Add the token to your `.env` file:

```env
GIT_TOKEN=ghp_your_token_here
```

### Step 4: Verify Token

Test your token by running:

```bash
./code-review-guardian.sh --help
```

The script will verify the token is accessible when needed.

### GitHub Fine-Grained Personal Access Tokens (Alternative)

GitHub also supports fine-grained personal access tokens with more granular permissions:

1. Go to **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens**
2. Click **Generate new token**
3. Select your repository or organization
4. Grant the following permissions:
   - Repository permissions:
     - **Pull requests**: Read and write
     - **Metadata**: Read-only (automatic)
5. Generate and copy the token
6. Add to `.env` as shown above

---

## GitLab

### Step 1: Create/Login to GitLab Account

1. Go to [GitLab.com](https://gitlab.com) or your GitLab instance URL
2. If you don't have an account, click **Register** and complete the registration
3. If you have an account, click **Sign in**

### Step 2: Create Personal Access Token

1. Click on your profile picture in the top-right corner
2. Select **Preferences** (or **Edit profile**)
3. In the left sidebar, click **Access Tokens**
4. Fill in the token details:
   - **Token name**: e.g., "Code Review Guardian"
   - **Expiration date**: Set an expiration (optional but recommended)
   - **Select scopes**:
     - ✅ **api** (Full API access)
     - ✅ **write_repository** (Write repository content)
5. Click **Create personal access token**
6. **IMPORTANT:** Copy the token immediately. It will look like: `glpat-xxxxxxxxxxxxxxxxxxxx`
   - You won't be able to see it again after leaving the page
   - Store it securely

### Step 3: Add Token to Your Project

Add the token to your `.env` file:

```env
GIT_TOKEN=glpat-your_token_here
```

### Step 4: Verify Token

Test your token by running:

```bash
./code-review-guardian.sh --help
```

---

## Bitbucket

### Step 1: Create/Login to Bitbucket Account

1. Go to [Bitbucket.org](https://bitbucket.org)
2. If you don't have an account, click **Get started** and complete registration
3. If you have an account, click **Log in**

### Step 2: Create App Password

Bitbucket uses App Passwords instead of Personal Access Tokens:

1. Click on your profile picture in the bottom-left corner
2. Click **Personal settings**
3. In the left sidebar, click **App passwords** (under **Access management**)
4. Click **Create app password**
5. Fill in the details:
   - **Label**: e.g., "Code Review Guardian"
   - **Permissions**:
     - ✅ **Repositories**: Write
     - ✅ **Pull requests**: Write
6. Click **Create**
7. **IMPORTANT:** Copy the password immediately. It will look like a random string
   - You won't be able to see it again
   - Store it securely

### Step 3: Add Password to Your Project

Add the app password to your `.env` file:

```env
GIT_TOKEN=your_app_password_here
```

### Step 4: Verify Token

Test your app password by running:

```bash
./code-review-guardian.sh --help
```

---

## Self-Hosted Git Providers

If you're using a self-hosted GitLab or Bitbucket instance:

### GitLab (Self-Hosted)

Follow the same steps as GitLab.com, but use your self-hosted instance URL:
- Replace `gitlab.com` with your instance URL (e.g., `git.example.com`)

### Bitbucket Server/Data Center

1. Go to your Bitbucket instance
2. Click on your profile → **Personal settings** → **App passwords**
3. Follow the same steps as Bitbucket Cloud
4. Note: The token format may vary depending on your Bitbucket version

---

## CI/CD Configuration

For CI/CD pipelines, use secrets/variables instead of `.env` files:

### GitHub Actions

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `GIT_TOKEN`
5. Value: Your token
6. Click **Add secret**

In your workflow file:

```yaml
env:
  GIT_TOKEN: ${{ secrets.GIT_TOKEN }}
```

### GitLab CI/CD

1. Go to your project on GitLab
2. Click **Settings** → **CI/CD**
3. Expand **Variables**
4. Click **Add variable**
5. Key: `GIT_TOKEN`
6. Value: Your token
7. Check **Mask variable** (recommended)
8. Check **Protect variable** if needed
9. Click **Add variable**

In your `.gitlab-ci.yml`:

```yaml
variables:
  GIT_TOKEN: $GIT_TOKEN
```

### Bitbucket Pipelines

1. Go to your repository on Bitbucket
2. Click **Repository settings** → **Pipelines** → **Repository variables**
3. Click **Add variable**
4. Name: `GIT_TOKEN`
5. Value: Your app password
6. Check **Secured** (recommended)
7. Click **Add**

In your `bitbucket-pipelines.yml`:

```yaml
variables:
  GIT_TOKEN: $GIT_TOKEN
```

---

## Security Best Practices

1. **Never commit tokens** to version control
   - Always use `.env` files (which should be in `.gitignore`)
   - Use CI/CD secrets/variables for automated pipelines

2. **Use least privilege**
   - Only grant the minimum permissions needed
   - Review token permissions regularly

3. **Set expiration dates**
   - Use short expiration dates for tokens (30-90 days)
   - Rotate tokens regularly

4. **Use different tokens for different purposes**
   - Don't reuse the same token across multiple projects
   - Create separate tokens for development and production

5. **Monitor token usage**
   - Regularly review active tokens
   - Revoke unused or compromised tokens immediately

6. **Store tokens securely**
   - Use password managers for local development
   - Use encrypted secrets in CI/CD systems

---

## Troubleshooting

### Token not working

- Verify the token is correctly copied (no extra spaces)
- Check token hasn't expired
- Verify token has correct permissions/scopes
- Ensure `.env` file is in the project root
- Check environment variable name matches configuration

### Permission denied errors

- Verify token has write permissions (not just read)
- Check repository access permissions
- For organizations, ensure your account has necessary permissions

### Token not found

- Verify `.env` file exists in project root
- Check variable name in `.env` matches `api_token_env` in config
- For CI/CD, verify secret/variable is set correctly

### Rate limiting

- Git providers have API rate limits
- GitHub: 5,000 requests/hour for authenticated requests
- GitLab: 2,000 requests/hour for authenticated requests
- Bitbucket: Varies by plan
- If you hit limits, wait before retrying or contact provider support

---

## Additional Resources

- [GitHub Personal Access Tokens Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitLab Personal Access Tokens Documentation](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
- [Bitbucket App Passwords Documentation](https://support.atlassian.com/bitbucket-cloud/docs/app-passwords/)
- [Code Review Guardian Configuration Guide](CONFIGURATION.md)
- [Git Guardian Angel Setup Guide](GGA.md)

