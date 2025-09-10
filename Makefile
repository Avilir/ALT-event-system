.PHONY: help setup test coverage lint format type-check install dev-install build \
	publish publish-test publish-prod clean all format-check lint-fix fix-all quick \
	test-parallel watch coverage-report deps-tree outdated docs docs-clean docs-live \
	docs-linkcheck docs-coverage pre-commit version update-deps check-security

# Default target
.DEFAULT_GOAL := help

# Python and pip commands
PYTHON := python3
PIP := pip
VENV := venv
ACTIVATE := . $(VENV)/bin/activate

# Package name
PACKAGE_NAME := alt_event_system

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Setup development environment
	@echo "Setting up development environment..."
	@if [ ! -d "$(VENV)" ]; then \
		$(PYTHON) -m venv $(VENV); \
	fi
	@$(ACTIVATE) && $(PIP) install --upgrade pip setuptools wheel
	@$(ACTIVATE) && $(PIP) install -e ".[dev]"
	@$(ACTIVATE) && pre-commit install
	@echo "✓ Development environment ready!"
	@echo "  Activate with: source $(VENV)/bin/activate"

test: ## Run tests with verbose output
	@echo "Running tests..."
	@$(ACTIVATE) && pytest tests/ -v

coverage: ## Run tests with coverage report
	@echo "Running tests with coverage..."
	@$(ACTIVATE) && pytest tests/ -v --cov=alt_event_system --cov-report=term-missing --cov-report=html

lint: ## Run linting checks
	@echo "Running linting checks..."
	@$(ACTIVATE) && ruff check src tests

lint-fix: ## Run linting with automatic fixes
	@echo "Running linting with fixes..."
	@$(ACTIVATE) && ruff check src tests --fix

format: ## Format code style
	@echo "Formatting code..."
	@$(ACTIVATE) && black src tests
	@$(ACTIVATE) && ruff format src tests

format-check: ## Check code formatting without modifying
	@echo "Checking code format..."
	@$(ACTIVATE) && black --check src tests
	@$(ACTIVATE) && ruff format --check src tests

fix-all: lint-fix format ## Fix all linting issues and format code
	@echo "✓ All fixes applied!"

type-check: ## Run type checking
	@echo "Running type checking..."
	@$(ACTIVATE) && mypy src

install: ## Install the package
	@echo "Installing package..."
	@$(ACTIVATE) && $(PIP) install -e .

dev-install: ## Install with development dependencies
	@echo "Installing package with development dependencies..."
	@$(ACTIVATE) && $(PIP) install -e ".[dev]"

build: clean ## Build distribution packages
	@echo "Building distributions..."
	@$(ACTIVATE) && python -m build
	@echo "✓ Distributions built in dist/"

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf dist/
	@rm -rf *.egg-info
	@rm -rf src/*.egg-info
	@find . -type d -name __pycache__ -exec rm -rf {} +
	@find . -type f -name "*.pyc" -delete
	@find . -type f -name ".coverage" -delete
	@rm -rf htmlcov/
	@rm -rf .coverage
	@rm -rf .pytest_cache/
	@rm -rf .mypy_cache/
	@rm -rf .ruff_cache/

all: format lint type-check test ## Run all checks (format, lint, type-check, test)
	@echo "✓ All checks passed!"

# Publishing targets
publish: publish-prod ## Alias for publish-prod

publish-test: build ## Publish to TestPyPI
	@echo "Publishing to TestPyPI..."
	@./scripts/publish_pypi.sh test

publish-prod: build ## Publish to PyPI (production)
	@echo "Publishing to production PyPI..."
	@./scripts/publish_pypi.sh prod

# Additional useful targets
pre-commit: ## Run pre-commit on all files
	@echo "Running pre-commit..."
	@$(ACTIVATE) && pre-commit run --all-files

version: ## Show current version
	@echo "Current version:"
	@grep "^version" pyproject.toml | cut -d'"' -f2

quick: ## Quick format and lint check (no tests)
	@echo "Quick checks..."
	@$(ACTIVATE) && ruff check src tests --fix && ruff format src tests
	@echo "✓ Quick checks passed!"

test-parallel: ## Run tests in parallel (requires pytest-xdist)
	@echo "Running tests in parallel..."
	@$(ACTIVATE) && pytest -n auto 2>/dev/null || \
	(echo "Installing pytest-xdist..." && $(PIP) install pytest-xdist && pytest -n auto)

watch: ## Watch for changes and run tests (requires pytest-watch)
	@echo "Watching for changes..."
	@$(ACTIVATE) && ptw 2>/dev/null || \
	(echo "Installing pytest-watch..." && $(PIP) install pytest-watch && ptw)

coverage-report: coverage ## Generate and open coverage report
	@echo "Opening coverage report..."
	@python -m webbrowser htmlcov/index.html 2>/dev/null || \
	xdg-open htmlcov/index.html 2>/dev/null || \
	open htmlcov/index.html 2>/dev/null || \
	echo "Please open htmlcov/index.html in your browser"

update-deps: ## Update all dependencies
	@echo "Updating dependencies..."
	@$(ACTIVATE) && $(PIP) install --upgrade -e ".[dev]"

check-security: ## Check for security vulnerabilities
	@echo "Checking for security vulnerabilities..."
	@$(ACTIVATE) && pip-audit 2>/dev/null || \
	(echo "Installing pip-audit..." && $(PIP) install pip-audit && pip-audit)

deps-tree: ## Show dependency tree
	@echo "Dependency tree:"
	@$(ACTIVATE) && pipdeptree 2>/dev/null || \
	(echo "Installing pipdeptree..." && $(PIP) install pipdeptree && pipdeptree)

outdated: ## Check for outdated dependencies
	@echo "Checking for outdated packages..."
	@$(ACTIVATE) && pip list --outdated

# Documentation targets
docs: ## Build HTML documentation
	@echo "Building HTML documentation..."
	@$(ACTIVATE) && cd docs && make html
	@echo "✓ Documentation built in docs/build/html/"

docs-clean: ## Clean documentation build files
	@echo "Cleaning documentation..."
	@cd docs && make clean
	@rm -rf docs/build

docs-live: ## Serve documentation with live reload
	@echo "Starting documentation server with live reload..."
	@$(ACTIVATE) && sphinx-autobuild docs/source docs/build/html \
		--port 8000 --open-browser \
		2>/dev/null || \
	(echo "Installing sphinx-autobuild..." && \
	 $(PIP) install sphinx-autobuild && \
	 sphinx-autobuild docs/source docs/build/html --port 8000 --open-browser)

docs-linkcheck: ## Check documentation links
	@echo "Checking documentation links..."
	@$(ACTIVATE) && cd docs && make linkcheck

docs-coverage: ## Check documentation coverage
	@echo "Checking documentation coverage..."
	@$(ACTIVATE) && cd docs && make coverage
	@cat docs/build/coverage/python.txt