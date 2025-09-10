#!/bin/bash
#
# Script to check branch protection status for a GitHub repository
# Usage: ./check_branch_protection.sh <owner/repo> [branch]
# Example: ./check_branch_protection.sh Avilir/ALT-file-utils main
#

set -e

# Source common utilities
source "$(dirname "$0")/common_utils.sh"

# Script-specific configuration
REQUIRES_GITHUB_TOKEN=true

# Function to display usage
usage() {
    show_usage "$0" \
        "Check branch protection status for a GitHub repository" \
        "<owner/repo> [branch]" \
        "owner/repo  - GitHub repository (e.g., Avilir/ALT-file-utils)" \
        "branch      - Branch to check (default: main)"
    echo "Example: $0 Avilir/ALT-file-utils main"
    exit 1
}

# Function to display protection status
display_protection_status() {
    local body=$1
    
    success "✅ Branch protection is enabled"
    echo ""
    info "Current Protection Rules:"
    echo ""
    
    # Check if admins are included
    local enforce_admins=$(echo "$body" | jq -r '.enforce_admins.enabled // false')
    if [ "$enforce_admins" = "true" ]; then
        echo "• $(print_color "$GREEN" "Administrators included") (must follow rules)"
    else
        echo "• $(print_color "$YELLOW" "Administrators excluded") (can bypass rules)"
    fi
    
    # Check PR requirements
    local pr_required=$(echo "$body" | jq -r '.required_pull_request_reviews // null')
    if [ "$pr_required" != "null" ]; then
        echo ""
        info "Pull Request Requirements:"
        
        local approvals=$(echo "$pr_required" | jq -r '.required_approving_review_count // 0')
        echo "• Required approvals: $approvals"
        
        local dismiss_stale=$(echo "$pr_required" | jq -r '.dismiss_stale_reviews // false')
        if [ "$dismiss_stale" = "true" ]; then
            echo "• $(print_color "$GREEN" "Stale reviews dismissed on new commits")"
        fi
        
        local code_owners=$(echo "$pr_required" | jq -r '.require_code_owner_reviews // false')
        if [ "$code_owners" = "true" ]; then
            echo "• $(print_color "$GREEN" "Code owner reviews required")"
        fi
        
        local last_push=$(echo "$pr_required" | jq -r '.require_last_push_approval // false')
        if [ "$last_push" = "true" ]; then
            echo "• $(print_color "$GREEN" "Last push approval required")"
        fi
        
        # Check bypass allowances
        local bypass_users=$(echo "$pr_required" | jq -r '.bypass_pull_request_allowances.users[]? // empty' 2>/dev/null)
        if [ -n "$bypass_users" ]; then
            echo "• Users who can merge without approval:"
            echo "$bypass_users" | while read -r user; do
                echo "  - $user"
            done
        fi
    else
        echo "• $(print_color "$YELLOW" "Pull requests not required")"
    fi
    
    # Check status checks
    local status_checks=$(echo "$body" | jq -r '.required_status_checks // null')
    if [ "$status_checks" != "null" ]; then
        echo ""
        info "Status Check Requirements:"
        
        local strict=$(echo "$status_checks" | jq -r '.strict // false')
        if [ "$strict" = "true" ]; then
            echo "• $(print_color "$GREEN" "Branches must be up to date")"
        fi
        
        local contexts=$(echo "$status_checks" | jq -r '.contexts[]? // empty' 2>/dev/null)
        if [ -n "$contexts" ]; then
            echo "• Required checks:"
            echo "$contexts" | while read -r check; do
                echo "  - $check"
            done
        else
            echo "• No specific checks required"
        fi
    fi
    
    # Other settings
    echo ""
    info "Other Settings:"
    
    local conversation=$(echo "$body" | jq -r '.required_conversation_resolution // false')
    if [ "$conversation" = "true" ]; then
        echo "• $(print_color "$GREEN" "Conversation resolution required")"
    fi
    
    local linear=$(echo "$body" | jq -r '.required_linear_history // false')
    if [ "$linear" = "true" ]; then
        echo "• $(print_color "$GREEN" "Linear history required")"
    fi
    
    local force_push=$(echo "$body" | jq -r '.allow_force_pushes // false')
    if [ "$force_push" = "false" ]; then
        echo "• $(print_color "$GREEN" "Force pushes blocked")"
    fi
    
    local deletions=$(echo "$body" | jq -r '.allow_deletions // false')
    if [ "$deletions" = "false" ]; then
        echo "• $(print_color "$GREEN" "Branch deletion blocked")"
    fi
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
    
    info "Checking branch protection for ${YELLOW}$repo${BLUE} branch ${YELLOW}$branch${NC}"
    echo ""
    
    # Get branch protection status
    local response=$(github_api_request GET "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection")
    
    # Check response
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "404" ]; then
        warning "⚠️  Branch protection is not enabled"
        echo ""
        echo "To enable protection, run:"
        echo "./setup_branch_protection.sh $REPO_OWNER/$REPO_NAME $branch"
        exit 0
    elif [ "$http_code" = "200" ]; then
        display_protection_status "$body"
        echo ""
        success "View in GitHub: https://github.com/$REPO_OWNER/$REPO_NAME/settings/branches"
    else
        parse_api_response "$response" 200 > /dev/null
        exit 1
    fi
}

# Run main function
main "$@"