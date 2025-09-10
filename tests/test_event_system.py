"""
Unit tests for EventSystem and related classes.
"""

from datetime import datetime, timezone
from unittest.mock import Mock

import pytest

from alt_event_system import Event, EventSystem


def create_named_mock(name="mock_handler"):
    """Create a mock with a __name__ attribute."""
    mock = Mock()
    mock.__name__ = name
    return mock


class TestEvent:
    """Test cases for Event dataclass."""

    def test_event_creation(self):
        """Test creating an Event instance."""
        now = datetime.now(timezone.utc)
        event = Event(
            type="user.login",
            timestamp=now,
            data={"user_id": 123, "ip": "192.168.1.1"},
            source="auth_service",
        )

        assert event.type == "user.login"
        assert event.timestamp == now
        assert event.data == {"user_id": 123, "ip": "192.168.1.1"}
        assert event.source == "auth_service"

    def test_event_without_source(self):
        """Test creating an Event without source."""
        now = datetime.now(timezone.utc)
        event = Event(type="system.startup", timestamp=now, data={"version": "1.0.0"})

        assert event.type == "system.startup"
        assert event.source is None

    def test_event_string_representation(self):
        """Test Event string representation."""
        now = datetime.now(timezone.utc)
        event = Event(type="test.event", timestamp=now, data={}, source="test")

        assert "Event(test.event" in str(event)
        assert "source=test" in str(event)


@pytest.fixture
def event_system():
    """Create a fresh EventSystem instance for each test."""
    return EventSystem()
