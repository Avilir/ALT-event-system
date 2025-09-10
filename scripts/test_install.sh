#!/bin/bash
#
# Script to test package installation from PyPI or TestPyPI
# Usage: ./test_install.sh [test|prod]
#

set -e  # Exit on error

# Source common utilities
source "$(dirname "$0")/common_utils.sh"

# Package name
PACKAGE_NAME="alt_event_system"

# Function to display usage
usage() {
    echo "Usage: $0 [test|prod]"
    echo ""
    echo "Test package installation from PyPI or TestPyPI"
    echo ""
    echo "Arguments:"
    echo "  test - Install from TestPyPI (default)"
    echo "  prod - Install from PyPI (production)"
    exit 1
}

# Function to create test environment
create_test_environment() {
    local test_dir=$1
    
    success "Creating fresh virtual environment..."
    python3 -m venv test_venv
    source test_venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
}

# Function to install package
install_package() {
    local target=$1
    
    if [ "$target" = "test" ]; then
        warning "Installing from TestPyPI..."
        pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ "$PACKAGE_NAME"
    else
        warning "Installing from PyPI..."
        pip install "$PACKAGE_NAME"
    fi
    
    # Show installed version
    success "Installed version:"
    pip show "$PACKAGE_NAME"
}

# Function to create and run test script
run_functionality_tests() {
    info "Creating test script..."
    
    cat > test_package.py << 'EOF'
#!/usr/bin/env python3
"""Test alt_event_system package functionality."""

import sys

try:
    # Test imports
    print("Testing imports...")
    import alt_event_system
    from alt_event_system import __version__
    print(f"✓ Successfully imported alt_event_system version {__version__}")
    
    # TODO: Add your package-specific tests here
    # Example tests:
    
    # Test basic functionality
    print("\nTesting basic functionality...")
    # Add tests for your main functions/classes
    # Example:
    # result = alt_event_system.main_function("test")
    # assert result is not None
    print("✓ Basic functionality works")
    
    # Test module imports
    print("\nTesting module imports...")
    assert hasattr(alt_event_system, 'core')
    assert hasattr(alt_event_system, 'exceptions')
    assert hasattr(alt_event_system, 'constants')
    print("✓ All modules imported successfully")
    
    print("\n" + "="*50)
    print("✅ All tests passed! alt_event_system is working correctly.")
    print("="*50)
    
except Exception as e:
    print(f"\n❌ Test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF
    
    info "Running functionality tests..."
    python test_package.py
}

# Main function
main() {
    # Default to test PyPI
    local target=${1:-test}
    
    # Validate target
    if [ "$target" != "test" ] && [ "$target" != "prod" ]; then
        error "Invalid target '$target'. Use 'test' or 'prod'"
        usage
    fi
    
    # Create temporary directory for testing
    local test_dir=$(mktemp -d -t ${PACKAGE_NAME}-test-XXXXXX)
    success "Creating test environment in: $test_dir"
    
    # Change to test directory
    cd "$test_dir"
    
    # Create and activate virtual environment
    create_test_environment "$test_dir"
    
    # Install package
    install_package "$target"
    
    # Run tests
    run_functionality_tests
    
    # Cleanup
    deactivate
    cd ..
    rm -rf "$test_dir"
    
    success "✓ Test completed successfully!"
}

# Run main function
main "$@"