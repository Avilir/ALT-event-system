"""
Core event system implementation for publish-subscribe pattern.

This module provides an event-driven architecture that enables
components to communicate without tight coupling.
"""

import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Callable, Dict, List, Optional

from .constants import (
    DEFAULT_EVENT_HISTORY_LIMIT,
    DEFAULT_EVENT_HISTORY_QUERY_LIMIT,
)

logger = logging.getLogger(__name__)


@dataclass
class Event:
    """Represents an event in the system."""

    type: str
    timestamp: datetime
    data: Dict[str, Any]
    source: Optional[str] = None

    def __str__(self) -> str:
        return f"Event({self.type}, source={self.source}, timestamp={self.timestamp})"


class EventSystem:
    """
    Central event system for publishing and subscribing to events.

    This enables loose coupling between components by allowing them
    to communicate through events rather than direct dependencies.

    Features:
    - Subscribe to specific event types or use wildcards
    - Event history with configurable limits
    - Error isolation (handler failures don't affect other handlers)
    - Optional source tracking for events

    Example:
        >>> event_system = EventSystem()
        >>> event_system.subscribe("user.login", handle_login)
        >>> event_system.emit("user.login", {"user_id": 123})
    """

    def __init__(
        self, history_limit: int = DEFAULT_EVENT_HISTORY_LIMIT, log_errors: bool = True
    ) -> None:
        """
        Initialize the event system.

        Args:
            history_limit: Maximum number of events to keep in history
            log_errors: Whether to log handler errors
        """
        self._subscribers: Dict[str, List[Callable]] = {}
        self._event_history: List[Event] = []
        self._history_limit = history_limit
        self._log_errors = log_errors

    def subscribe(self, event_type: str, handler: Callable) -> None:
        """
        Subscribe to an event type.

        Args:
            event_type: The type of event to subscribe to. Use "*" for all events.
            handler: Callable that will be invoked when the event occurs.
                     Should accept a single Event parameter.

        Example:
            >>> def on_user_login(event: Event):
            ...     print(f"User {event.data['user_id']} logged in")
            >>> event_system.subscribe("user.login", on_user_login)
        """
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []

        self._subscribers[event_type].append(handler)

        if self._log_errors:
            handler_name = getattr(handler, "__name__", repr(handler))
            logger.debug(f"Handler {handler_name} subscribed to {event_type}")

    def unsubscribe(self, event_type: str, handler: Callable) -> None:
        """
        Unsubscribe from an event type.

        Args:
            event_type: The type of event to unsubscribe from
            handler: The handler to remove
        """
        if event_type in self._subscribers:
            try:
                self._subscribers[event_type].remove(handler)
                if self._log_errors:
                    handler_name = getattr(handler, "__name__", repr(handler))
                    logger.debug(
                        f"Handler {handler_name} unsubscribed from {event_type}"
                    )
            except ValueError:
                if self._log_errors:
                    handler_name = getattr(handler, "__name__", repr(handler))
                    logger.warning(
                        f"Handler {handler_name} was not subscribed to {event_type}"
                    )

    def emit(
        self, event_type: str, data: Dict[str, Any], source: Optional[str] = None
    ) -> None:
        """
        Emit an event to all subscribers.

        Args:
            event_type: The type of event to emit
            data: Event data to pass to handlers
            source: Optional source identifier

        Example:
            >>> event_system.emit("user.login", {"user_id": 123, "ip": "192.168.1.1"})
        """
        event = Event(
            type=event_type,
            timestamp=datetime.now(timezone.utc),
            data=data,
            source=source,
        )

        # Add to history
        self._add_to_history(event)

        # Notify specific subscribers
        if event_type in self._subscribers:
            self._notify_handlers(self._subscribers[event_type], event)

        # Also notify wildcard subscribers
        if "*" in self._subscribers:
            self._notify_handlers(self._subscribers["*"], event)

    def _notify_handlers(self, handlers: List[Callable], event: Event) -> None:
        """Notify a list of handlers about an event."""
        for handler in handlers:
            try:
                handler(event)
            except Exception as e:
                if self._log_errors:
                    handler_name = getattr(handler, "__name__", repr(handler))
                    logger.error(
                        f"Error in event handler {handler_name} for {event.type}: {e}"
                    )

    def _add_to_history(self, event: Event) -> None:
        """Add event to history, maintaining size limit."""
        self._event_history.append(event)

        # Trim history if needed
        if len(self._event_history) > self._history_limit:
            self._event_history = self._event_history[-self._history_limit :]

    def get_history(
        self,
        event_type: Optional[str] = None,
        limit: int = DEFAULT_EVENT_HISTORY_QUERY_LIMIT,
    ) -> List[Event]:
        """
        Get event history.

        Args:
            event_type: Optional filter by event type
            limit: Maximum number of events to return

        Returns:
            List of events from history (most recent last)
        """
        if event_type:
            filtered = [e for e in self._event_history if e.type == event_type]
            return filtered[-limit:]
        else:
            return self._event_history[-limit:]

    def clear_history(self) -> None:
        """Clear the event history."""
        self._event_history.clear()

    def get_subscriber_count(self, event_type: str) -> int:
        """
        Get the number of subscribers for an event type.

        Args:
            event_type: The event type to check

        Returns:
            Number of subscribers
        """
        return len(self._subscribers.get(event_type, []))

    def get_all_event_types(self) -> List[str]:
        """
        Get all event types that have subscribers.

        Returns:
            List of event types
        """
        return list(self._subscribers.keys())

    def clear_all_subscriptions(self) -> None:
        """Remove all event subscriptions."""
        self._subscribers.clear()
        if self._log_errors:
            logger.debug("All event subscriptions cleared")
