"""
Tests for EventSystem history functionality.
"""

from alt_event_system import EventSystem


class TestEventHistory:
    """Test event history functionality."""

    def test_event_history(self):
        """Test event history tracking."""
        system = EventSystem()
        system.emit("action.started", {"id": "1"})
        system.emit("action.completed", {"id": "2"})
        system.emit("action.failed", {"id": "3"})

        history = system.get_history()
        assert len(history) == 3
        assert history[0].type == "action.started"
        assert history[1].type == "action.completed"
        assert history[2].type == "action.failed"

    def test_event_history_with_filter(self):
        """Test getting filtered event history."""
        system = EventSystem()
        system.emit("user.login", {"id": "1"})
        system.emit("user.logout", {"id": "1"})
        system.emit("user.login", {"id": "2"})
        system.emit("user.action", {"id": "2"})

        login_events = system.get_history(event_type="user.login")
        assert len(login_events) == 2
        assert all(e.type == "user.login" for e in login_events)

    def test_event_history_limit(self):
        """Test event history respects query limit."""
        system = EventSystem()
        # Add 10 events
        for i in range(10):
            system.emit("test.event", {"id": i})

        history = system.get_history(limit=5)
        assert len(history) == 5
        # Should get the last 5 events
        assert history[0].data["id"] == 5
        assert history[-1].data["id"] == 9

    def test_event_history_size_limit(self):
        """Test event history respects size limit."""
        # Create system with small history limit
        system = EventSystem(history_limit=5)

        # Add 10 events
        for i in range(10):
            system.emit("test.event", {"id": i})

        assert len(system._event_history) == 5
        # Should keep only the last 5
        assert system._event_history[0].data["id"] == 5
        assert system._event_history[-1].data["id"] == 9

    def test_clear_history(self):
        """Test clearing event history."""
        system = EventSystem()
        # Add some events
        system.emit("test.started", {})
        system.emit("test.ended", {})
        assert len(system._event_history) > 0

        # Clear history
        system.clear_history()
        assert len(system._event_history) == 0

    def test_get_subscriber_count(self):
        """Test getting subscriber count for event types."""
        system = EventSystem()

        def handler1(event):
            pass

        def handler2(event):
            pass

        assert system.get_subscriber_count("test.event") == 0

        system.subscribe("test.event", handler1)
        assert system.get_subscriber_count("test.event") == 1

        system.subscribe("test.event", handler2)
        assert system.get_subscriber_count("test.event") == 2

    def test_comprehensive_event_flow(self):
        """Test a comprehensive event flow scenario."""
        system = EventSystem()
        results = {"orders": [], "all_events": []}

        def handle_order_created(event):
            if event.type == "order.created":
                results["orders"].append(event)

        def handle_all(event):
            results["all_events"].append(event)

        # Set up subscriptions
        system.subscribe("order.created", handle_order_created)
        system.subscribe("*", handle_all)

        # Simulate business flow
        system.emit("order.created", {"order_id": "123", "total": 100})
        system.emit("order.validated", {"order_id": "123"})
        system.emit(
            "notification.sent", {"to": "customer@example.com", "order_id": "123"}
        )
        system.emit("order.shipped", {"order_id": "123", "tracking": "ABC123"})

        # Verify results
        assert len(results["all_events"]) == 4  # Wildcard gets everything
        assert len(results["orders"]) == 1  # Only order.created events

        # Verify event order and data
        assert results["all_events"][0].type == "order.created"
        assert results["all_events"][0].data["total"] == 100
        assert results["all_events"][-1].type == "order.shipped"
