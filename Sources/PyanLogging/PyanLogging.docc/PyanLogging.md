# ``PyanLogging``

Category-based structured logging built on swift-log and Apple's unified logging system.

## Overview

PyanLogging extends [swift-log](https://github.com/apple/swift-log) with category support, an `os.Logger`-backed
handler, thread-safe metadata management, and utilities for attaching contextual metadata to log messages.

### Features

- Category-scoped loggers via ``LoggerFactory``
- Native `os.Logger` integration via ``OSLogHandler``
- Thread-safe metadata management via ``MetadataContainer``
- Structured metadata attachment via ``LoggerAttachable``
- Nested metadata flattening with configurable path representations

### Basic Example

```swift
import PyanLogging

// 1. Bootstrap swift-log with OSLogHandler
LoggingSystem.bootstrap { label in
    OSLogHandler(label: label, category: "Default")
}

// 2. Define your categories
enum AppLogCategory: String, LogCategory {
    case network
    case database
}

// 3. Create a factory and obtain loggers
let factory = LoggerFactory<AppLogCategory>(label: "com.example.myapp")
let logger = factory.logger(for: .network)

logger.info("Request sent")
```

`LoggerFactory` also supports custom handler factories and metadata
providers — see <doc:GettingStarted> for details.

## Topics

### Essentials

- <doc:GettingStarted>
- ``LoggerFactory``
- ``LogCategory``
- ``Swift.Logger/categorized(_:)``

### Log Handlers

- ``OSLogHandler``
- ``OSLogHandler/MetadataStyle``
- ``LogHandlerWithCategory``
- ``CategoryAdderLogHandler``

### Metadata

- ``MetadataContainer``
- ``MetadataKey``
- ``LoggerAttachable``
- ``NestedPathRepresentation``
