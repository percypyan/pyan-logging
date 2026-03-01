# PyanLogging

Category-based structured logging built on swift-log and Apple's unified logging system.

## Features

- Category-scoped loggers via `LoggerFactory`
- Native `os.Logger` integration via `OSLogHandler`
- Thread-safe metadata management via `MetadataContainer`
- Structured metadata attachment via `LoggerAttachable`
- Nested metadata flattening with configurable path representations

## Requirements

### Platform

- iOS 18.0+
- macOS 15.0+
- tvOS 18.0+
- watchOS 11.0+
- visionOS 2.0+
- Linux
- Windows

> Notice: `OSLogHandler` will be unavailable on Linux and Windows.

### Toolchain

- Swift 6.2+

## Installation

Add PyanLogging to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/percypyan/PyanLogging.git", .upToNextMajor("0.1.0"))
]
```

## Quick Start

```swift
import PyanLogging

// Bootstrap swift-log with OSLogHandler
LoggingSystem.bootstrap { label in
    OSLogHandler(label: label, category: "Default")
}

// Define your categories
enum AppLogCategory: String, LogCategory {
    case network
    case database
}

// Create a factory and obtain loggers
let factory = LoggerFactory<AppLogCategory>(label: "com.example.myapp")
let logger = factory.logger(for: .network)

logger.info("Request sent")
```

### Custom Handler Factory

Pass a factory closure for full control over the log handler:

```swift
let factory = LoggerFactory<AppLogCategory>(
    label: "com.example.myapp",
    factory: { label in
        OSLogHandler(label: label, category: "Default")
    }
)
```

### Categorizing an Existing Logger

Assign a category to any `Logger` instance directly:

```swift
var logger = Logger(label: "com.example.myapp")
let categorized = logger.categorized(AppLogCategory.network)
```

### Metadata Provider

Attach dynamic metadata to every logger the factory produces:

```swift
let metadata = MetadataContainer<AppMetadataKey>()
let factory = LoggerFactory<AppLogCategory>(
    label: "com.example.myapp",
    metadataProvider: metadata.provider
)
```

## Documentation

For detailed usage and examples, see the [Getting Started](Sources/PyanLogging/PyanLogging.docc/GettingStarted.md) guide.

## AI disclaimer

The code of this package is **entirely human-written**.
However, AI has been used to _generate unit tests suites and documentation_. Every generated bit of code or
documentation has been **reviewed and approved by a human developer**.

## License

The repository use an MIT licence.

See [LICENSE](LICENSE.md) file for details.
