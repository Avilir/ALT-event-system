#!/bin/bash
#
# Script to publish package to PyPI (test or production)
# Usage: ./publish_pypi.sh [test|prod]
#
# This script handles:
# - Virtual environment activation
# - Distribution file validation
# - Credentials via environment variables or interactive prompt
# - Keyring issues on Linux systems
# - Safety confirmation for production releases
#

set -e  # Exit on error

# Source common utilities
source "$(dirname "$0")/common_utils.sh"

# Script configuration
PACKAGE_NAME="alt_event_system"

# Function to display usage
usage() {
    echo "Usage: $0 [test|prod]"
    echo ""
    echo "Publish package to PyPI or TestPyPI"
    echo ""
    echo "Arguments:"
    echo "  test - Publish to TestPyPI"
    echo "  prod - Publish to PyPI (production)"
    exit 1
}

# Check distribution files
check_dist_files() {
    if [ ! -d "dist" ] || [ -z "$(ls -A dist 2>/dev/null)" ]; then
        error "No distribution files found in dist/"
        echo "Run 'make build' first to create distribution files"
        return 1
    fi
    
    # Count files to upload
    local file_count=$(ls -1 dist/* 2>/dev/null | wc -l)
    info "Found $file_count distribution file(s)"
    return 0
}

# Get package version from distribution files
get_package_version() {
    local version=$(ls dist/*.whl 2>/dev/null | head -1 | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+[^-]*)-.*$/\1/')
    if [ -n "$version" ]; then
        echo "$version"
    fi
}

# Display upload details
display_upload_info() {
    local target=$1
    local repo_display=$2
    
    success "Files to upload:"
    ls -la dist/
    
    local version=$(get_package_version)
    if [ -n "$version" ]; then
        info "Package version: $version"
    fi
    
    if [ "$target" = "prod" ]; then
        echo ""
        warning "⚠️  WARNING: You are about to publish to production PyPI!"
        warning "   This action cannot be undone. The version $version will be permanently registered."
        echo ""
        
        if ! confirm_strict "Type 'yes' to confirm production release" "yes"; then
            error "Publishing cancelled"
            exit 0
        fi
    fi
}

# Display credentials help
display_credentials_help() {
    local target=$1
    
    info "Credentials setup:"
    warning "1. For API tokens (recommended):"
    echo "   - Username: __token__"
    echo "   - Password: <your-api-token>"
    echo ""
    warning "2. For username/password:"
    echo "   - Username: <your-pypi-username>"
    echo "   - Password: <your-pypi-password>"
    echo ""
    
    if [ "$target" = "test" ]; then
        warning "Note: Use your test.pypi.org credentials"
    else
        warning "Note: Use your pypi.org credentials"
    fi
    echo ""
}

# Display installation instructions
display_install_instructions() {
    local target=$1
    local package_name=$2
    local version=$3
    
    echo ""
    success "✅ Successfully published $package_name $version to $REPO_DISPLAY!"
    echo ""
    
    if [ "$target" = "test" ]; then
        success "To install from TestPyPI:"
        echo "pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ $package_name"
        echo ""
        info "View package at: https://test.pypi.org/project/$package_name/"
    else
        success "To install from PyPI:"
        echo "pip install $package_name"
        echo ""
        info "View package at: https://pypi.org/project/$package_name/"
    fi
}

# Display next steps
display_next_steps() {
    local target=$1
    local version=$2
    
    echo ""
    success "Next steps:"
    
    if [ "$target" = "test" ]; then
        echo "1. Test installation: ./scripts/test_install.sh test"
        echo "2. If everything works, publish to production: make publish-prod"
    else
        echo "1. Create a Git tag: git tag -a v$version -m 'Release version $version'"
        echo "2. Push tag: git push origin v$version"
        echo "3. Create GitHub release with changelog"
    fi
}

# Handle upload failure
handle_upload_failure() {
    local target=$1
    
    echo ""
    error "Upload failed!"
    echo ""
    warning "Troubleshooting tips:"
    echo "1. Check your credentials (username/password or API token)"
    echo "2. For API tokens, ensure username is '__token__'"
    echo "3. Verify your account has upload permissions"
    echo "4. Check if this version already exists on $REPO_DISPLAY"
    echo ""
    
    if [ "$target" = "test" ]; then
        echo "5. Create account at: https://test.pypi.org/account/register/"
        echo "6. Generate API token at: https://test.pypi.org/manage/account/token/"
    else
        echo "5. Create account at: https://pypi.org/account/register/"
        echo "6. Generate API token at: https://pypi.org/manage/account/token/"
    fi
}

# Main script
main() {
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Check if virtual environment is activated and activate if needed
    activate_venv || exit 1
    
    # Check if twine is installed
    ensure_package "twine"
    
    # Check command line argument
    if [ $# -eq 0 ]; then
        error "Please specify 'test' or 'prod' as argument"
        usage
    fi
    
    local target=$1
    
    # Validate target
    if [ "$target" != "test" ] && [ "$target" != "prod" ]; then
        error "Invalid target '$target'. Use 'test' or 'prod'"
        exit 1
    fi
    
    # Check if distribution files exist
    check_dist_files || exit 1
    
    # Check distribution files
    success "Checking distribution files..."
    twine check dist/*
    
    # Set repository configuration based on target
    local repo_name
    local repo_display
    
    if [ "$target" = "test" ]; then
        repo_name="testpypi"
        repo_display="TestPyPI"
        warning "Publishing to TestPyPI..."
    else
        repo_name="pypi"
        repo_display="PyPI (Production)"
        warning "Publishing to PyPI (Production)..."
    fi
    
    # Show what will be uploaded
    display_upload_info "$target" "$repo_display"
    
    # Get version for later use
    local version=$(get_package_version)
    
    # Disable keyring to avoid SecretService errors on Linux
    export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
    
    # Check for credentials
    echo ""
    if [ -n "$TWINE_USERNAME" ] && [ -n "$TWINE_PASSWORD" ]; then
        success "Using credentials from environment variables"
    else
        display_credentials_help "$target"
    fi
    
    # Upload to PyPI
    success "Uploading to $repo_display..."
    
    if ! twine upload --repository "$repo_name" dist/* --verbose; then
        handle_upload_failure "$target"
        exit 1
    fi
    
    # Display success and instructions
    display_install_instructions "$target" "$PACKAGE_NAME" "$version"
    display_next_steps "$target" "$version"
}

# Export repository display name for use in functions
export REPO_DISPLAY

# Run main function
main "$@"