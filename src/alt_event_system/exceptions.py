"""
Custom exceptions for ALT-event-system.
"""


class EventSystemError(Exception):
    """Base exception for all event system errors."""

    pass


class HandlerError(EventSystemError):
    """Raised when an event handler encounters an error."""

    pass


class EventTypeError(EventSystemError):
    """Raised when there's an issue with event type."""

    pass


class HistoryError(EventSystemError):
    """Raised when there's an issue with event history."""

    pass
