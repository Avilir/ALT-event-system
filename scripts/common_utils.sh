#!/bin/bash
#
# Common utilities for project scripts
# This file should be sourced by other scripts: source "$(dirname "$0")/common_utils.sh"
#

# ========================================
# Color codes for output
# ========================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# ========================================
# Common configuration
# ========================================
export GITHUB_API_URL="https://api.github.com"
export DEFAULT_BRANCH="main"

# Get script directory and project root
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ========================================
# Output functions
# ========================================

# Print colored message
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print error message
error() {
    print_color "$RED" "Error: $1" >&2
}

# Print warning message
warning() {
    print_color "$YELLOW" "Warning: $1"
}

# Print info message
info() {
    print_color "$BLUE" "$1"
}

# Print success message
success() {
    print_color "$GREEN" "$1"
}

# Print section header
print_header() {
    local title=$1
    local width=${2:-55}
    local line=$(printf '═%.0s' $(seq 1 $width))
    echo -e "${BLUE}${line}${NC}"
    echo -e "${BLUE}$(printf "%*s" $(((width + ${#title}) / 2)) "$title")${NC}"
    echo -e "${BLUE}${line}${NC}"
}

# ========================================
# Validation functions
# ========================================

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Validate repository format (owner/repo)
validate_repo_format() {
    local repo=$1
    if [[ ! "$repo" =~ ^[^/]+/[^/]+$ ]]; then
        error "Invalid repository format. Use 'owner/repo'"
        return 1
    fi
    return 0
}

# Extract owner and repo name from owner/repo format
parse_repo() {
    local repo=$1
    export REPO_OWNER=$(echo "$repo" | cut -d'/' -f1)
    export REPO_NAME=$(echo "$repo" | cut -d'/' -f2)
}

# ========================================
# GitHub API functions
# ========================================

# Check if GitHub token is set
check_github_token() {
    if [ -z "$GITHUB_TOKEN" ]; then
        error "GITHUB_TOKEN environment variable not set"
        echo ""
        echo "To create a token:"
        echo "1. Go to https://github.com/settings/tokens"
        echo "2. Click 'Generate new token (classic)'"
        echo "3. Select required scopes"
        echo "4. Generate and copy the token"
        echo ""
        echo "Then set it:"
        echo "export GITHUB_TOKEN='your-token-here'"
        return 1
    fi
    return 0
}

# Make authenticated GitHub API request
github_api_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    local args=(
        -s
        -w "\n%{http_code}"
        -X "$method"
        -H "Authorization: token $GITHUB_TOKEN"
        -H "Accept: application/vnd.github.v3+json"
    )
    
    if [ -n "$data" ]; then
        args+=(-H "Content-Type: application/json" -d "$data")
    fi
    
    curl "${args[@]}" "${GITHUB_API_URL}${endpoint}"
}

# Parse API response and check for errors
parse_api_response() {
    local response=$1
    local expected_code=$2
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected_code" ]; then
        echo "$body"
        return 0
    else
        case "$http_code" in
            401) error "Unauthorized - check your GITHUB_TOKEN" ;;
            403) error "Forbidden - insufficient permissions" ;;
            404) error "Not found - check repository/resource exists" ;;
            422) error "Validation failed - check input data" ;;
            *) error "API request failed (HTTP $http_code)" ;;
        esac
        echo "Response: $body" >&2
        return 1
    fi
}

# Get authenticated user
get_github_user() {
    local response=$(github_api_request GET "/user")
    local user=$(parse_api_response "$response" 200 | jq -r '.login')
    
    if [ "$user" = "null" ] || [ -z "$user" ]; then
        error "Could not authenticate with GitHub"
        return 1
    fi
    
    echo "$user"
}

# ========================================
# Virtual environment functions
# ========================================

# Check if virtual environment is activated
check_venv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        return 1
    fi
    return 0
}

# Activate virtual environment if not already active
activate_venv() {
    if check_venv; then
        return 0
    fi
    
    warning "Virtual environment not activated. Activating..."
    
    local venv_paths=("venv/bin/activate" ".venv/bin/activate" "env/bin/activate")
    
    for venv_path in "${venv_paths[@]}"; do
        if [ -f "$PROJECT_ROOT/$venv_path" ]; then
            source "$PROJECT_ROOT/$venv_path"
            success "Virtual environment activated"
            return 0
        fi
    done
    
    error "Virtual environment not found"
    echo "Please run: python -m venv venv && source venv/bin/activate"
    return 1
}

# ========================================
# Package functions
# ========================================

# Install package if not present
ensure_package() {
    local package=$1
    local import_name=${2:-$package}
    
    if ! python -c "import $import_name" &> /dev/null; then
        warning "$package not found. Installing..."
        pip install "$package"
    fi
}

# ========================================
# Confirmation functions
# ========================================

# Ask for confirmation
confirm() {
    local prompt=$1
    local default=${2:-no}
    
    local choices
    if [ "$default" = "yes" ]; then
        choices="[Y/n]"
        default_choice="y"
    else
        choices="[y/N]"
        default_choice="n"
    fi
    
    read -p "$prompt $choices: " response
    response=${response:-$default_choice}
    
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Ask for strict confirmation (must type exact phrase)
confirm_strict() {
    local prompt=$1
    local expected=$2
    
    read -p "$prompt: " response
    if [ "$response" = "$expected" ]; then
        return 0
    else
        return 1
    fi
}

# ========================================
# Usage function builder
# ========================================

# Display usage with consistent formatting
show_usage() {
    local script_name=$1
    local description=$2
    shift 2
    
    echo "Usage: $script_name $1"
    echo ""
    echo "$description"
    echo ""
    
    shift
    if [ $# -gt 0 ]; then
        echo "Arguments:"
        while [ $# -gt 0 ]; do
            echo "  $1"
            shift
        done
        echo ""
    fi
    
    if [ -n "$REQUIRES_GITHUB_TOKEN" ]; then
        echo "Environment variables:"
        echo "  GITHUB_TOKEN - GitHub personal access token (required)"
        echo ""
    fi
}

# ========================================
# Progress indicators
# ========================================

# Show spinner for long-running operations
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ========================================
# File operations
# ========================================

# Backup file before modification
backup_file() {
    local file=$1
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file" ]; then
        cp "$file" "$backup"
        info "Backed up $file to $backup"
    fi
}

# ========================================
# Export utility functions
# ========================================

# Make functions available to sourcing scripts
export -f print_color error warning info success print_header
export -f command_exists validate_repo_format parse_repo
export -f check_github_token github_api_request parse_api_response get_github_user
export -f check_venv activate_venv ensure_package
export -f confirm confirm_strict show_usage
export -f spinner backup_file
