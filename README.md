# ALT-event-system

> A lightweight, flexible publish-subscribe event system for Python applications.

[![PyPI version](https://badge.fury.io/py/ALT-event-system.svg)](https://badge.fury.io/py/ALT-event-system)
[![Python Support](https://img.shields.io/pypi/pyversions/ALT-event-system.svg)](https://pypi.org/project/ALT-event-system/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

ALT-event-system provides a simple yet powerful event-driven architecture that enables loose coupling between components through an event bus pattern. Perfect for building reactive applications, plugin systems, or any scenario where you need decoupled communication.

## Features

- 🚀 **Simple API** - Easy to understand and use
- 🎯 **Type-safe** - Full type hints for better IDE support
- 🔌 **Loose Coupling** - Components communicate without direct dependencies
- 🌟 **Wildcard Subscriptions** - Subscribe to all events with `*`
- 📜 **Event History** - Track and query past events
- 🛡️ **Error Isolation** - Handler errors don't affect other handlers
- 🔍 **Source Tracking** - Optional source identification for events
- ⚡ **Zero Dependencies** - Uses only Python standard library

## Installation

```bash
pip install ALT-event-system
```

## Quick Start

```python
from alt_event_system import EventSystem

# Create an event system
events = EventSystem()

# Define a handler
def on_user_login(event):
    print(f"User {event.data['user_id']} logged in from {event.data['ip']}")

# Subscribe to events
events.subscribe("user.login", on_user_login)

# Emit events
events.emit("user.login", {"user_id": 123, "ip": "192.168.1.1"})
```

## Advanced Usage

### Wildcard Subscriptions

Subscribe to all events:
```python
def log_all_events(event):
    print(f"[{event.timestamp}] {event.type}: {event.data}")

events.subscribe("*", log_all_events)
```

### Event History

Track and query past events:
```python
# Get recent events
history = events.get_history(limit=10)

# Filter by event type
login_events = events.get_history(event_type="user.login")
```

### Error Handling

Handler errors are isolated:
```python
def safe_handler(event):
    print("I still work even if others fail!")

events.subscribe("test.event", safe_handler)
```

## API Reference

- `EventSystem()` - Create a new event system
- `subscribe(event_type, handler)` - Subscribe to events
- `emit(event_type, data, source=None)` - Emit an event
- `get_history(event_type=None, limit=100)` - Get event history
- `clear_history()` - Clear event history
- `get_subscriber_count(event_type)` - Count subscribers

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

**Avi Layani** - [avilayani@gmail.com](mailto:avilayani@gmail.com)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.