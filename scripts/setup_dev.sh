#!/bin/bash
#
# Development setup script for {{project_name}}
# Usage: ./setup_dev.sh
#

set -e  # Exit on error

# Source common utilities
source "$(dirname "$0")/common_utils.sh"

# Script configuration
REQUIRED_PYTHON_VERSION="3.8"

# Function to check Python version
check_python_version() {
    warning "Checking Python version..."
    python3 --version
    
    local python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    
    if [ "$(printf '%s\n' "$REQUIRED_PYTHON_VERSION" "$python_version" | sort -V | head -n1)" != "$REQUIRED_PYTHON_VERSION" ]; then
        error "Python $REQUIRED_PYTHON_VERSION or higher is required (found $python_version)"
        return 1
    fi
    
    success "Python version $python_version is compatible"
    return 0
}

# Function to create virtual environment
setup_virtual_environment() {
    if [ ! -d "venv" ]; then
        success "Creating virtual environment..."
        python3 -m venv venv
    else
        warning "Virtual environment already exists"
    fi
    
    # Activate it
    success "Activating virtual environment..."
    source venv/bin/activate
}

# Function to upgrade base packages
upgrade_base_packages() {
    success "Upgrading pip, setuptools, and wheel..."
    pip install --upgrade pip setuptools wheel
}

# Function to install dependencies
install_dependencies() {
    success "Installing package with development dependencies..."
    pip install -e ".[dev]"
}

# Function to setup pre-commit hooks
setup_precommit() {
    if command_exists pre-commit; then
        success "Installing pre-commit hooks..."
        pre-commit install
        # Run pre-commit on all files to ensure everything is set up
        pre-commit run --all-files || warning "Some pre-commit checks need attention"
    else
        warning "pre-commit not found, skipping hook installation"
    fi
}

# Function to create project directories
create_project_directories() {
    success "Creating project directories..."
    local dirs=(
        "htmlcov"
        "dist"
        ".mypy_cache"
        ".pytest_cache"
        ".ruff_cache"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
}

# Function to run quality checks
run_quality_checks() {
    info "Running initial quality checks..."
    
    # Linting
    warning "Running linting..."
    if ruff check .; then
        success "✓ No linting issues found"
    else
        warning "⚠ Some linting issues found (run 'make lint' to see details)"
    fi
    
    # Type checking
    warning "Running type checks..."
    if mypy src; then
        success "✓ No type issues found"
    else
        warning "⚠ Some type issues found (run 'make type-check' to see details)"
    fi
    
    # Run tests
    warning "Running tests..."
    if pytest --tb=short -q; then
        success "✓ All tests passed"
    else
        warning "⚠ Some tests failed (run 'make test' to see details)"
    fi
}

# Function to display completion message
display_completion_message() {
    echo ""
    success "✓ Development environment setup complete!"
    echo ""
    
    info "To activate the environment in the future, run:"
    echo "  ${YELLOW}source venv/bin/activate${NC}"
    echo ""
    
    info "Available make commands:"
    echo "  ${YELLOW}make help${NC}         - Show all available commands"
    echo "  ${YELLOW}make test${NC}         - Run tests with coverage"
    echo "  ${YELLOW}make lint${NC}         - Run linting checks"
    echo "  ${YELLOW}make format${NC}       - Format code automatically"
    echo "  ${YELLOW}make type-check${NC}   - Run type checking"
    echo "  ${YELLOW}make all${NC}          - Run all quality checks"
    echo "  ${YELLOW}make build${NC}        - Build distribution packages"
    echo "  ${YELLOW}make publish-test${NC} - Publish to TestPyPI"
    echo "  ${YELLOW}make publish-prod${NC} - Publish to PyPI"
    echo ""
    
    success "Happy coding!"
}

# Main function
main() {
    print_header "Setting up {{project_name}} development environment"
    echo ""
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Check Python version
    check_python_version || exit 1
    
    # Setup virtual environment
    setup_virtual_environment
    
    # Upgrade base packages
    upgrade_base_packages
    
    # Install dependencies
    install_dependencies
    
    # Setup pre-commit hooks
    setup_precommit
    
    # Create necessary directories
    create_project_directories
    
    # Run initial quality checks
    run_quality_checks
    
    # Display completion message
    display_completion_message
}

# Run main function
main "$@"