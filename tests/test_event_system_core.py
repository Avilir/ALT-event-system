"""
Core functionality tests for EventSystem.
"""

import logging
from unittest.mock import Mock

from alt_event_system import Event, EventSystem


def create_named_mock(name="mock_handler"):
    """Create a mock with a __name__ attribute."""
    mock = Mock()
    mock.__name__ = name
    return mock


class TestEventSystemCore:
    """Test core EventSystem functionality."""

    def test_event_system_creation(self):
        """Test creating an EventSystem instance."""
        system = EventSystem()
        assert isinstance(system, EventSystem)
        assert system._history_limit == 1000  # Default
        assert system._log_errors is True  # Default

    def test_event_system_custom_limits(self):
        """Test creating EventSystem with custom limits."""
        system = EventSystem(history_limit=50, log_errors=False)
        assert system._history_limit == 50
        assert system._log_errors is False

    def test_subscribe_to_event(self):
        """Test subscribing to an event type."""
        system = EventSystem()
        handler = create_named_mock()
        system.subscribe("user.login", handler)

        assert system.get_subscriber_count("user.login") == 1

    def test_subscribe_multiple_handlers(self):
        """Test subscribing multiple handlers to the same event."""
        system = EventSystem()
        handler1 = create_named_mock("handler1")
        handler2 = create_named_mock("handler2")

        system.subscribe("order.created", handler1)
        system.subscribe("order.created", handler2)

        assert system.get_subscriber_count("order.created") == 2

    def test_unsubscribe_from_event(self):
        """Test unsubscribing from an event."""
        system = EventSystem()
        handler = create_named_mock()
        system.subscribe("user.logout", handler)
        assert system.get_subscriber_count("user.logout") == 1

        system.unsubscribe("user.logout", handler)
        assert system.get_subscriber_count("user.logout") == 0

    def test_unsubscribe_nonexistent_handler(self):
        """Test unsubscribing a handler that was never subscribed."""
        system = EventSystem()
        handler = create_named_mock()
        # Should not raise any exceptions
        system.unsubscribe("some.event", handler)

    def test_emit_event(self):
        """Test emitting an event to subscribers."""
        system = EventSystem()
        handler = create_named_mock()
        system.subscribe("payment.processed", handler)
        system.emit(
            "payment.processed",
            {"amount": 100.0, "currency": "USD"},
            source="payment_service",
        )

        # Verify handler was called
        handler.assert_called_once()
        event = handler.call_args[0][0]
        assert isinstance(event, Event)
        assert event.type == "payment.processed"
        assert event.data == {"amount": 100.0, "currency": "USD"}
        assert event.source == "payment_service"

    def test_emit_to_multiple_handlers(self):
        """Test emitting to multiple handlers."""
        system = EventSystem()
        handler1 = create_named_mock("handler1")
        handler2 = create_named_mock("handler2")

        system.subscribe("notification.sent", handler1)
        system.subscribe("notification.sent", handler2)

        system.emit(
            "notification.sent", {"message": "Hello", "recipient": "user@example.com"}
        )

        assert handler1.call_count == 1
        assert handler2.call_count == 1

    def test_emit_to_nonexistent_event(self):
        """Test emitting an event with no subscribers."""
        system = EventSystem()
        # Should not raise any exceptions
        system.emit("nonexistent.event", {})

    def test_wildcard_subscription(self):
        """Test subscribing to all events with wildcard."""
        system = EventSystem()
        wildcard_handler = create_named_mock("wildcard")
        specific_handler = create_named_mock("specific")

        system.subscribe("*", wildcard_handler)
        system.subscribe("user.action", specific_handler)

        system.emit("user.action", {"action": "click"})
        system.emit("system.event", {"type": "startup"})
        system.emit("random.event", {"data": "test"})

        # Wildcard handler should receive all events
        assert wildcard_handler.call_count == 3
        # Specific handler only receives its event
        assert specific_handler.call_count == 1

    def test_handler_exception_handling(self, caplog):
        """Test that handler exceptions don't affect other handlers."""
        system = EventSystem()
        failing_handler = Mock(side_effect=Exception("Handler error"))
        failing_handler.__name__ = "failing_handler"

        working_handler = create_named_mock("working_handler")

        system.subscribe("test.event", failing_handler)
        system.subscribe("test.event", working_handler)

        data = {"test": "data"}
        system.emit("test.event", data)

        # Working handler should still be called despite failing handler
        working_handler.assert_called_once()

        # Error should be logged
        assert "Error in event handler failing_handler" in caplog.text

    def test_get_all_event_types(self):
        """Test getting all event types with subscribers."""
        system = EventSystem()
        assert system.get_all_event_types() == []

        system.subscribe("user.login", create_named_mock())
        system.subscribe("user.logout", create_named_mock())
        system.subscribe("*", create_named_mock())

        types = system.get_all_event_types()
        assert len(types) == 3
        assert "user.login" in types
        assert "user.logout" in types
        assert "*" in types

    def test_clear_all_subscriptions(self):
        """Test clearing all subscriptions."""
        system = EventSystem()
        system.subscribe("event1", create_named_mock())
        system.subscribe("event2", create_named_mock())
        system.subscribe("*", create_named_mock())

        assert len(system.get_all_event_types()) == 3

        system.clear_all_subscriptions()
        assert len(system.get_all_event_types()) == 0

    def test_no_logging_mode(self, caplog):
        """Test EventSystem with logging disabled."""
        system = EventSystem(log_errors=False)

        handler = Mock(side_effect=Exception("Test error"))
        handler.__name__ = "test_handler"

        system.subscribe("test.event", handler)

        with caplog.at_level(logging.ERROR):
            system.emit("test.event", {})

        # Should not log errors when log_errors=False
        assert "Error in event handler" not in caplog.text
