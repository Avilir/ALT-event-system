# Contributing to ALT-event-system

Thank you for your interest in contributing to ALT-event-system! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our code of conduct: be respectful, inclusive, and constructive in all interactions.

## How to Contribute

### Reporting Issues

1. Check existing issues to avoid duplicates
2. Use issue templates when available
3. Provide clear, detailed information:
   - Python version
   - alt_event_system version
   - Minimal reproducible example
   - Expected vs actual behavior
   - Error messages/tracebacks

### Submitting Changes

1. **Fork the Repository**
   ```bash
   git clone https://github.com/Avilir/ALT-event-system.git
   cd ALT-event-system
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Set Up Development Environment**
   ```bash
   make setup
   # or
   ./scripts/setup_dev.sh
   ```

4. **Make Your Changes**
   - Follow existing code style
   - Add/update tests as needed
   - Update documentation if applicable
   - Keep commits focused and atomic

5. **Run Quality Checks**
   ```bash
   make all  # Runs lint, format, type-check, and tests
   ```

6. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature X

   - Detailed description of what changed
   - Why the change was made
   - Any breaking changes or migration notes"
   ```

   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` New features
   - `fix:` Bug fixes
   - `docs:` Documentation changes
   - `test:` Test additions/changes
   - `refactor:` Code refactoring
   - `chore:` Maintenance tasks

7. **Push and Create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a PR on GitHub.

## Pull Request Guidelines

### PR Requirements

- **Title**: Clear, descriptive title following conventional commits
- **Description**: 
  - What changes were made
  - Why they were made
  - Link to related issues
  - Breaking changes (if any)
- **Tests**: All tests must pass
- **Coverage**: Maintain or improve code coverage
- **Lint**: No linting errors (`make lint`)
- **Type Check**: No mypy errors (`make type-check`)
- **Documentation**: Update relevant docs

### PR Process

1. Create PR against `main` branch
2. Ensure all checks pass
3. Wait for code review
4. Address feedback
5. Maintainer will merge when approved

## Development Guidelines

### Code Style

- Follow PEP 8
- Use type hints for all functions
- Maximum line length: 100 characters
- Use descriptive variable names
- Add docstrings to all public functions

### Testing

- Write tests for new features
- Maintain test coverage above 80%
- Use pytest for testing
- Mock external dependencies
- Test edge cases and error conditions

Example test:
```python
def test_feature_success(tmp_path):
    """Test successful feature operation."""
    # Arrange
    input_data = {"key": "value"}
    
    # Act
    result = my_feature(input_data)
    
    # Assert
    assert result == expected_output
```

### Documentation

- Update docstrings for API changes
- Update README for new features
- Update wiki documentation if needed
- Include examples in docstrings

## Project Structure

```
ALT-event-system/
├── src/alt_event_system/  # Source code
│   ├── __init__.py       # Package initialization
│   ├── core.py           # Core functionality
│   ├── exceptions.py     # Custom exceptions
│   └── constants.py      # Constants
├── tests/                # Test suite
├── scripts/              # Development scripts
├── docs/                 # Documentation
└── .github/              # GitHub configuration
```

## Getting Help

- Check the [Wiki](https://github.com/Avilir/ALT-event-system/wiki)
- Review existing [Issues](https://github.com/Avilir/ALT-event-system/issues)
- Ask questions in issue discussions

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes
- Project documentation

Thank you for contributing to ALT-event-system!
