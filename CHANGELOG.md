# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-09-08

### Added
- Initial release of ALT-event-system
- Core `EventSystem` class with publish-subscribe functionality
- `Event` dataclass for structured event data
- Wildcard subscriptions support (`*` subscribes to all events)
- Event history tracking with configurable limits
- Error isolation (handler failures don't affect other handlers)
- Optional source tracking for events
- Comprehensive test suite
- Full type hints for better IDE support
- Zero external dependencies