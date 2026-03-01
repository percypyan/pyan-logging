# Getting Started

Set up structured, category-based logging in your application.

## Overview

This guide walks through bootstrapping the logging system, defining
categories, creating loggers, and attaching metadata.

## Bootstrapping

PyanLogging ships with ``OSLogHandler``, which routes log messages to
Apple's unified logging system. Register it at app launch:

```swift
import PyanLogging

LoggingSystem.bootstrap { label in
    OSLogHandler(label: label, category: "Default")
}
```

## Defining Categories

Create a `String`-backed enum conforming to ``LogCategory``:

```swift
enum AppLogCategory: String, LogCategory {
    case network
    case database
    case ui
}
```

The default ``LogCategory/label`` implementation capitalizes the raw value
(e.g. `"network"` becomes `"Network"`). Override ``LogCategory/label`` for
custom formatting.

## Creating Loggers

Use ``LoggerFactory`` to produce loggers scoped to a category:

```swift
let factory = LoggerFactory<AppLogCategory>(label: "com.example.myapp")
let networkLogger = factory.logger(for: .network)

networkLogger.info("Request completed")
```

The factory checks whether the bootstrapped handler conforms to
``LogHandlerWithCategory``. If so, the category is set directly.
Otherwise the handler is wrapped in a ``CategoryAdderLogHandler``.

### Custom Handler Factory

If you need full control over the log handler, pass a factory closure:

```swift
let factory = LoggerFactory<AppLogCategory>(
    label: "com.example.myapp",
    factory: { label in
        OSLogHandler(label: label, category: "Default")
    }
)
```

A variant that also receives the metadata provider is available:

```swift
let factory = LoggerFactory<AppLogCategory>(
    label: "com.example.myapp",
    factory: { label, metadataProvider in
        OSLogHandler(
            label: label,
            category: "Default",
            metadataProvider: metadataProvider
        )
    }
)
```

### Metadata Style

``OSLogHandler`` supports different metadata formatting styles via
``OSLogHandler/MetadataStyle``. Pass the desired style at initialization:

```swift
LoggingSystem.bootstrap { label in
    OSLogHandler(
        label: label,
        category: "Default",
        metadataStyle: .multiline
    )
}
```

Available styles:

| Style | Output |
|---|---|
| ``OSLogHandler/MetadataStyle/oneLine`` (default) | `> key1 = value1 \| key2 = value2` |
| ``OSLogHandler/MetadataStyle/multiline`` | Each pair on its own `> ` prefixed line |
| ``OSLogHandler/MetadataStyle/dictionary`` | The metadata dictionary's printed on multiple lines |
| ``OSLogHandler/MetadataStyle/hidden`` | Metadata is omitted entirely |

### Metadata Provider

To attach dynamic metadata to every logger the factory produces, pass a
``MetadataContainer/provider``:

```swift
let metadata = MetadataContainer<AppMetadataKey>()
let factory = LoggerFactory<AppLogCategory>(
    label: "com.example.myapp",
    metadataProvider: metadata.provider
)
```

### Categorizing an Existing Logger

If you already have a `Logger` instance created outside of
``LoggerFactory``, you can assign a category to it directly with
`categorized(_:)`:

```swift
var logger = Logger(label: "com.example.myapp")
let categorized = logger.categorized(AppLogCategory.network)

categorized.info("Request completed")
```

## Managing Global Metadata

``MetadataContainer`` provides a thread-safe store for metadata that
should appear on every log message. Define your keys with ``MetadataKey``:

```swift
enum AppMetadataKey: String, MetadataKey {
    case userId
    case sessionId
}

let metadata = MetadataContainer<AppMetadataKey>()
metadata
    .update(.userId, value: "abc-123")
    .update(.sessionId, value: "session-456")
```

Pass the container's ``MetadataContainer/provider`` to your log handler
so metadata is included automatically:

```swift
LoggingSystem.bootstrap { label in
    OSLogHandler(
        label: label,
        category: "Default",
        metadataProvider: metadata.provider
    )
}
```

## Attaching Contextual Metadata

Conform types to ``LoggerAttachable`` to let them contribute metadata to
a logger:

```swift
struct User: LoggerAttachable {
    let id: String
    let name: String

    var logMetadata: Logger.Metadata {
        ["id": .string(id), "name": .string(name)]
    }
}

let user = User(id: "42", name: "Alice")
logger
    .attaching(key: "user", user)
    .info("Profile loaded")
// Log output includes in addition to existing metadata:
// ["user": ["id": 42, "name": "Alice"]]
```
