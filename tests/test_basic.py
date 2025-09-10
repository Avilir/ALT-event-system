"""Basic tests for ALT-event-system package."""

import alt_event_system


def test_package_has_version():
    """Test that the package has a version."""
    assert hasattr(alt_event_system, "__version__")
    assert isinstance(alt_event_system.__version__, str)
    assert alt_event_system.__version__ == "0.1.0"


def test_all_exports():
    """Test that all expected classes and constants are exported."""
    expected_exports = [
        # Core classes
        "Event",
        "EventSystem",
        # Constants
        "DEFAULT_EVENT_HISTORY_LIMIT",
        "DEFAULT_EVENT_HISTORY_QUERY_LIMIT",
        # Exceptions
        "EventSystemError",
        "HandlerError",
        "EventTypeError",
        "HistoryError",
    ]

    for export in expected_exports:
        assert hasattr(alt_event_system, export), f"Missing export: {export}"
