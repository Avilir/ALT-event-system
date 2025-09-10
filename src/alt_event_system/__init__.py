"""
ALT-event-system: A generic publish-subscribe event system for Python.

This package provides a flexible event-driven architecture that enables
loose coupling between components through an event bus pattern.
"""

from .constants import (
    DEFAULT_EVENT_HISTORY_LIMIT,
    DEFAULT_EVENT_HISTORY_QUERY_LIMIT,
)
from .core import Event, EventSystem
from .exceptions import (
    EventSystemError,
    EventTypeError,
    HandlerError,
    HistoryError,
)

__version__ = "0.1.0"

__all__ = [
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
