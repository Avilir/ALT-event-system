# Branch Protection Scripts

These scripts help you manage GitHub branch protection rules via the API.

## Prerequisites

1. **GitHub Personal Access Token**
   - Go to https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scope: `repo` (all permissions)
   - Copy the token

2. **Set the token as environment variable**
   ```bash
   export GITHUB_TOKEN='your-token-here'
   ```

3. **Install jq** (for JSON parsing)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # macOS
   brew install jq
   
   # Fedora
   sudo dnf install jq
   ```

## Usage

### setup_branch_protection.sh

Sets up branch protection with these rules:
- PR required for all changes
- 1 approval required (except for the authenticated user)
- Stale reviews dismissed on new commits
- Conversations must be resolved
- Admins can bypass rules
- Force pushes and deletions blocked

```bash
# Make executable
chmod +x setup_branch_protection.sh

# Run for a repository
./setup_branch_protection.sh Avilir/ALT-file-utils main

# Or for different branch
./setup_branch_protection.sh owner/repo develop
```

### check_branch_protection.sh

Checks current branch protection status:

```bash
# Make executable
chmod +x check_branch_protection.sh

# Check protection status
./check_branch_protection.sh Avilir/ALT-file-utils main
```

## Examples

### Setting Protection for Multiple Repos

```bash
# Set token once
export GITHUB_TOKEN='ghp_yourtoken123...'

# Apply to multiple repositories
for repo in ALT-file-utils ALT-error-handling ALT-time-utils; do
    ./setup_branch_protection.sh Avilir/$repo main
done
```

### Checking All Branches

```bash
# Check main and develop branches
for branch in main develop; do
    echo "=== Checking $branch ==="
    ./check_branch_protection.sh Avilir/ALT-file-utils $branch
    echo
done
```

## Protection Rules Applied

The script automatically detects if it's a personal or organization repository and applies appropriate rules:

### For Personal Repositories:
1. **Pull Request Reviews**
   - 1 approval required
   - Dismiss stale reviews
   - Admins can merge without approval

2. **Status Checks**
   - Branches must be up to date
   - Can add specific checks later

3. **Restrictions**
   - No force pushes
   - No branch deletion
   - Conversation resolution required

4. **Admin Settings**
   - Admins can bypass (not enforced)

### For Organization Repositories (additional features):
1. **Pull Request Reviews**
   - Can specify users who can dismiss reviews
   - Can specify users who bypass PR requirements
   - More granular control over permissions

**Note**: Personal repositories have limitations - they cannot use dismissal restrictions or bypass allowances for specific users/teams. The script handles this automatically.

## Customization

To modify the rules, edit the `PROTECTION_RULES` JSON in `setup_branch_protection.sh`:

```bash
# Example: Require 2 approvals
"required_approving_review_count": 2

# Example: Require code owner reviews
"require_code_owner_reviews": true

# Example: Enforce rules for admins too
"enforce_admins": true
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check your GITHUB_TOKEN is set correctly
   - Ensure token hasn't expired

2. **403 Forbidden**
   - Verify you have admin access to the repository
   - Check token has `repo` scope

3. **404 Not Found**
   - Ensure repository exists and is accessible
   - Check branch name is correct

### Debug Mode

Add `-x` to see what's happening:
```bash
bash -x setup_branch_protection.sh owner/repo main
```

## Security Notes

- Never commit your GitHub token
- Consider using GitHub's fine-grained tokens for specific repos
- Tokens should be treated as passwords
- Regularly rotate your tokens

## Additional Resources

- [GitHub Branch Protection API](https://docs.github.com/en/rest/branches/branch-protection)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [jq Manual](https://stedolan.github.io/jq/manual/)
