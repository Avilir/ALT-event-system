#!/bin/bash
#
# Script to set up branch protection rules for a GitHub repository
# Usage: ./setup_branch_protection.sh <owner/repo> [branch]
# Example: ./setup_branch_protection.sh Avilir/ALT-file-utils main
#

set -e

# Source common utilities
source "$(dirname "$0")/common_utils.sh"

# Script-specific configuration
REQUIRES_GITHUB_TOKEN=true

# Function to display usage
usage() {
    show_usage "$0" \
        "Set up branch protection rules for a GitHub repository" \
        "<owner/repo> [branch]" \
        "owner/repo  - GitHub repository (e.g., Avilir/ALT-file-utils)" \
        "branch      - Branch to protect (default: main)"
    echo "Example: $0 Avilir/ALT-file-utils main"
    exit 1
}

# Generate protection rules based on repository type
generate_protection_rules() {
    local is_org=$1
    local auth_user=$2
    
    if [ "$is_org" = "Organization" ]; then
        # Organization repository - can use all features
        cat <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismissal_restrictions": {
      "users": ["$auth_user"],
      "teams": []
    },
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1,
    "require_last_push_approval": false,
    "bypass_pull_request_allowances": {
      "users": ["$auth_user"],
      "teams": []
    }
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
    else
        # Personal repository - limited features
        cat <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
    fi
}

# Display success message with details
display_success() {
    local is_org=$1
    local auth_user=$2
    
    success "✅ Branch protection successfully applied!"
    echo ""
    info "Protection rules applied:"
    echo "• Pull requests required for all changes"
    echo "• 1 approval required"
    echo "• Stale PR approvals dismissed on new commits"
    echo "• Conversations must be resolved before merging"
    
    if [ "$is_org" = "Organization" ]; then
        echo "• $auth_user can dismiss reviews and bypass PR requirements"
    else
        echo "• As admin, you can merge without approval when needed"
    fi
    
    echo "• Administrators can bypass (enforce_admins: false)"
    echo "• Force pushes and deletions blocked"
}

# Main script
main() {
    # Check arguments
    if [ $# -lt 1 ]; then
        usage
    fi
    
    # Parse arguments
    local repo=$1
    local branch=${2:-$DEFAULT_BRANCH}
    
    # Validate repository format and parse
    validate_repo_format "$repo" || exit 1
    parse_repo "$repo"
    
    # Check for GitHub token
    check_github_token || exit 1
    
    info "Setting up branch protection for ${YELLOW}$repo${BLUE} branch ${YELLOW}$branch${NC}"
    echo ""
    
    # Get authenticated user
    success "Getting authenticated user..."
    local auth_user=$(get_github_user)
    
    if [ -z "$auth_user" ]; then
        exit 1
    fi
    
    info "Authenticated as: ${YELLOW}$auth_user${NC}"
    echo ""
    
    # Check if it's an organization repo
    local response=$(github_api_request GET "/repos/$REPO_OWNER/$REPO_NAME")
    local is_org=$(parse_api_response "$response" 200 | jq -r '.owner.type')
    
    info "Repository type: ${YELLOW}$is_org${NC}"
    
    # Generate protection rules
    local protection_rules=$(generate_protection_rules "$is_org" "$auth_user")
    
    # Apply branch protection
    success "Applying branch protection rules..."
    response=$(github_api_request PUT "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection" "$protection_rules")
    
    # Check response
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        display_success "$is_org" "$auth_user"
        echo ""
        success "View settings at: https://github.com/$REPO_OWNER/$REPO_NAME/settings/branches"
    else
        # Handle specific error codes
        case "$http_code" in
            404)
                error "Repository or branch not found"
                echo "Check that:"
                echo "• Repository exists: https://github.com/$REPO_OWNER/$REPO_NAME"
                echo "• Branch '$branch' exists"
                echo "• You have admin access to the repository"
                exit 1
                ;;
            403)
                error "Forbidden - insufficient permissions"
                echo "Make sure your token has 'repo' scope and you have admin access"
                exit 1
                ;;
            401)
                error "Unauthorized - check your GITHUB_TOKEN"
                exit 1
                ;;
            *)
                parse_api_response "$response" 200 > /dev/null
                exit 1
                ;;
        esac
    fi
    
    # Check for existing status checks
    echo ""
    warning "Checking for existing status checks..."
    
    response=$(github_api_request GET "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection/required_status_checks" 2>/dev/null || true)
    
    if [ -n "$response" ] && [ "$(echo "$response" | tail -n1)" = "200" ]; then
        info "Found existing status checks. Keeping them enabled."
    else
        info "No existing status checks found."
        echo ""
        warning "To add status checks later:"
        echo "1. Let GitHub Actions run at least once"
        echo "2. Go to branch protection settings"
        echo "3. Add the workflow as a required check"
    fi
    
    echo ""
    success "✅ Branch protection setup complete!"
    echo ""
    info "Next steps:"
    echo "1. Create a test PR to verify settings"
    echo "2. Add specific status checks as needed"
    echo "3. Configure CODEOWNERS file for automatic reviews"
    echo "4. Document the PR process in CONTRIBUTING.md"
}

# Run main function
main "$@"