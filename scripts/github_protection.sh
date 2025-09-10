#!/bin/bash
#
# Unified GitHub branch protection management script
# Usage: ./github_protection.sh <command> <owner/repo> [branch] [options]
#
# Commands:
#   check   - Check current branch protection status
#   setup   - Set up branch protection rules
#   update  - Update existing branch protection rules
#   remove  - Remove branch protection
#   compare - Compare protection between branches
#

set -e

# Source common utilities
source "$(dirname "$0")/common_utils.sh"

# Script configuration
REQUIRES_GITHUB_TOKEN=true
SCRIPT_NAME=$(basename "$0")

# Function to display usage
usage() {
    print_header "GitHub Branch Protection Manager"
    echo ""
    echo "Usage: $SCRIPT_NAME <command> <owner/repo> [branch] [options]"
    echo ""
    echo "Commands:"
    echo "  check    Check current branch protection status"
    echo "  setup    Set up branch protection rules"
    echo "  update   Update existing branch protection rules"
    echo "  remove   Remove branch protection"
    echo "  compare  Compare protection between branches"
    echo ""
    echo "Arguments:"
    echo "  owner/repo  GitHub repository (e.g., Avilir/ALT-file-utils)"
    echo "  branch      Branch name (default: main)"
    echo ""
    echo "Options:"
    echo "  --strict    Enable strict protection (enforce for admins)"
    echo "  --minimal   Set minimal protection (PR only)"
    echo "  --status    Include status checks"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME check Avilir/my-repo"
    echo "  $SCRIPT_NAME setup Avilir/my-repo main --strict"
    echo "  $SCRIPT_NAME compare Avilir/my-repo main develop"
    echo ""
    echo "Environment variables:"
    echo "  GITHUB_TOKEN  GitHub personal access token (required)"
    exit 1
}

# Generate protection rules
generate_protection_rules() {
    local mode=$1
    local is_org=$2
    local auth_user=$3
    
    case "$mode" in
        "default")
            if [ "$is_org" = "Organization" ]; then
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
            ;;
            
        "strict")
            cat <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 2,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
EOF
            ;;
            
        "minimal")
            cat <<EOF
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
            ;;
    esac
}

# Parse protection status
parse_protection_status() {
    local body=$1
    local verbose=${2:-true}
    
    if [ "$verbose" = "true" ]; then
        success "✅ Branch protection is enabled"
        echo ""
        info "Protection Rules:"
        echo ""
    fi
    
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
        local approvals=$(echo "$pr_required" | jq -r '.required_approving_review_count // 0')
        echo "• Required approvals: $approvals"
        
        local dismiss_stale=$(echo "$pr_required" | jq -r '.dismiss_stale_reviews // false')
        [ "$dismiss_stale" = "true" ] && echo "• Stale reviews dismissed on new commits"
        
        local code_owners=$(echo "$pr_required" | jq -r '.require_code_owner_reviews // false')
        [ "$code_owners" = "true" ] && echo "• Code owner reviews required"
        
        local last_push=$(echo "$pr_required" | jq -r '.require_last_push_approval // false')
        [ "$last_push" = "true" ] && echo "• Last push approval required"
    else
        echo "• $(print_color "$YELLOW" "Pull requests not required")"
    fi
    
    # Check status checks
    local status_checks=$(echo "$body" | jq -r '.required_status_checks // null')
    if [ "$status_checks" != "null" ]; then
        local strict=$(echo "$status_checks" | jq -r '.strict // false')
        [ "$strict" = "true" ] && echo "• Branches must be up to date before merging"
        
        local contexts=$(echo "$status_checks" | jq -r '.contexts[]? // empty' 2>/dev/null | wc -l)
        [ "$contexts" -gt 0 ] && echo "• $contexts required status checks"
    fi
    
    # Other settings
    local conversation=$(echo "$body" | jq -r '.required_conversation_resolution // false')
    [ "$conversation" = "true" ] && echo "• Conversation resolution required"
    
    local linear=$(echo "$body" | jq -r '.required_linear_history // false')
    [ "$linear" = "true" ] && echo "• Linear history required"
    
    local force_push=$(echo "$body" | jq -r '.allow_force_pushes // false')
    [ "$force_push" = "false" ] && echo "• Force pushes blocked"
}

# Command: check
cmd_check() {
    local repo=$1
    local branch=$2
    
    info "Checking branch protection for ${YELLOW}$repo${BLUE} branch ${YELLOW}$branch${NC}"
    echo ""
    
    local response=$(github_api_request GET "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection")
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "404" ]; then
        warning "⚠️  Branch protection is not enabled"
        echo ""
        echo "To enable protection, run:"
        echo "$SCRIPT_NAME setup $repo $branch"
    elif [ "$http_code" = "200" ]; then
        local body=$(echo "$response" | sed '$d')
        parse_protection_status "$body"
        echo ""
        success "View in GitHub: https://github.com/$REPO_OWNER/$REPO_NAME/settings/branches"
    else
        parse_api_response "$response" 200 > /dev/null
    fi
}

# Command: setup
cmd_setup() {
    local repo=$1
    local branch=$2
    local mode="default"
    
    # Parse additional options
    shift 2
    while [ $# -gt 0 ]; do
        case "$1" in
            --strict) mode="strict" ;;
            --minimal) mode="minimal" ;;
            --status) include_status=true ;;
        esac
        shift
    done
    
    info "Setting up branch protection for ${YELLOW}$repo${BLUE} branch ${YELLOW}$branch${NC}"
    echo ""
    
    # Get authenticated user
    local auth_user=$(get_github_user)
    [ -z "$auth_user" ] && exit 1
    
    info "Authenticated as: ${YELLOW}$auth_user${NC}"
    
    # Check repository type
    local response=$(github_api_request GET "/repos/$REPO_OWNER/$REPO_NAME")
    local is_org=$(parse_api_response "$response" 200 | jq -r '.owner.type')
    
    info "Repository type: ${YELLOW}$is_org${NC}"
    info "Protection mode: ${YELLOW}$mode${NC}"
    echo ""
    
    # Generate and apply rules
    local rules=$(generate_protection_rules "$mode" "$is_org" "$auth_user")
    
    success "Applying branch protection rules..."
    response=$(github_api_request PUT "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection" "$rules")
    
    if [ "$(echo "$response" | tail -n1)" = "200" ]; then
        success "✅ Branch protection successfully applied!"
        echo ""
        local body=$(echo "$response" | sed '$d')
        parse_protection_status "$body"
        echo ""
        success "View settings at: https://github.com/$REPO_OWNER/$REPO_NAME/settings/branches"
    else
        parse_api_response "$response" 200 > /dev/null
    fi
}

# Command: update
cmd_update() {
    local repo=$1
    local branch=$2
    
    info "Updating branch protection for ${YELLOW}$repo${BLUE} branch ${YELLOW}$branch${NC}"
    echo ""
    
    # First get current settings
    local response=$(github_api_request GET "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection")
    
    if [ "$(echo "$response" | tail -n1)" != "200" ]; then
        error "Branch protection not found. Use 'setup' command first."
        exit 1
    fi
    
    warning "Update functionality coming soon..."
    echo "For now, use 'setup' command with desired options to reconfigure"
}

# Command: remove
cmd_remove() {
    local repo=$1
    local branch=$2
    
    warning "⚠️  Removing branch protection for ${YELLOW}$repo${BLUE} branch ${YELLOW}$branch${NC}"
    echo ""
    
    if ! confirm "Are you sure you want to remove branch protection?" "no"; then
        info "Operation cancelled"
        exit 0
    fi
    
    local response=$(github_api_request DELETE "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection")
    
    if [ "$(echo "$response" | tail -n1)" = "204" ]; then
        success "✅ Branch protection removed successfully"
    else
        parse_api_response "$response" 204 > /dev/null
    fi
}

# Command: compare
cmd_compare() {
    local repo=$1
    local branch1=$2
    local branch2=$3
    
    if [ -z "$branch2" ]; then
        error "Two branches required for comparison"
        echo "Usage: $SCRIPT_NAME compare <owner/repo> <branch1> <branch2>"
        exit 1
    fi
    
    info "Comparing protection between ${YELLOW}$branch1${BLUE} and ${YELLOW}$branch2${NC}"
    echo ""
    
    # Get protection for both branches
    local response1=$(github_api_request GET "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch1/protection")
    local response2=$(github_api_request GET "/repos/$REPO_OWNER/$REPO_NAME/branches/$branch2/protection")
    
    local status1=$(echo "$response1" | tail -n1)
    local status2=$(echo "$response2" | tail -n1)
    
    echo "Branch: ${YELLOW}$branch1${NC}"
    if [ "$status1" = "200" ]; then
        parse_protection_status "$(echo "$response1" | sed '$d')" false
    else
        warning "  No protection enabled"
    fi
    
    echo ""
    echo "Branch: ${YELLOW}$branch2${NC}"
    if [ "$status2" = "200" ]; then
        parse_protection_status "$(echo "$response2" | sed '$d')" false
    else
        warning "  No protection enabled"
    fi
}

# Main function
main() {
    # Check for minimum arguments
    if [ $# -lt 2 ]; then
        usage
    fi
    
    local command=$1
    local repo=$2
    local branch=${3:-$DEFAULT_BRANCH}
    
    # Validate repository format
    validate_repo_format "$repo" || exit 1
    parse_repo "$repo"
    
    # Check GitHub token
    check_github_token || exit 1
    
    # Execute command
    case "$command" in
        check) cmd_check "$repo" "$branch" ;;
        setup) cmd_setup "$repo" "$branch" "$@" ;;
        update) cmd_update "$repo" "$branch" ;;
        remove) cmd_remove "$repo" "$branch" ;;
        compare) cmd_compare "$repo" "$branch" "$3" ;;
        *) error "Unknown command: $command"; usage ;;
    esac
}

# Run main function
main "$@"
