//
//  OSLogHandler.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

import os
import Synchronization
import Testing
@testable import PyanLogging

/// Counting `OSLoggerProvider` for tests: records every category requested
/// and returns a fresh `os.Logger` each time. Lets tests assert on lookup
/// behaviour without relying on `os.Logger`'s opaque identity.
final class CountingOSLoggerProvider: OSLoggerProvider, Sendable {
	private let log: Mutex<[String]>

	init() {
		self.log = Mutex([])
	}

	func osLogger(for category: String) -> os.Logger {
		log.withLock { $0.append(category) }
		return os.Logger(subsystem: "test.counting", category: category)
	}

	/// The categories requested so far, in order.
	var requestedCategories: [String] {
		log.withLock { $0 }
	}
}

@Suite("OSLogHandler")
struct OSLogHandlerTests {

	@Test("Implemented with value type semantics")
	func logHandlerValueSemantics() {
		let handler = OSLogHandler(label: "test", category: "UnitTest")
		checkValueSemanticImplementation(of: handler)
	}

	// MARK: - prepareMetadata

	@Suite("prepareMetadata")
	struct PrepareMetadataTests {

		@Test("Merges handler metadata with explicit metadata")
		func mergesHandlerAndExplicit() {
			let result = OSLogHandler.prepareMetadata(
				base: ["handler": "base"],
				provider: nil,
				explicit: ["explicit": "extra"]
			)
			#expect(result?["handler"] == "base")
			#expect(result?["explicit"] == "extra")
		}

		@Test("Explicit metadata overrides handler metadata for same key")
		func explicitOverridesHandler() {
			let result = OSLogHandler.prepareMetadata(
				base: ["key": "from-handler"],
				provider: nil,
				explicit: ["key": "from-explicit"]
			)
			#expect(result?["key"] == "from-explicit")
		}

		@Test("Merges provider metadata into the result")
		func mergesProviderMetadata() {
			let provider = Logging.Logger.MetadataProvider { ["provided": "dynamic"] }
			let result = OSLogHandler.prepareMetadata(
				base: [:],
				provider: provider,
				explicit: nil
			)
			#expect(result?["provided"] == "dynamic")
		}
	}

	// MARK: - resolveCategory

	@Suite("resolveCategory")
	struct ResolveCategoryTests {

		@Test("Falls back to default when logger.category is absent")
		func defaultWhenAbsent() {
			let result = OSLogHandler.resolveCategory(
				from: ["other": "value"],
				default: "Default"
			)
			#expect(result.category == "Default")
			#expect(result.usedMetadata == false)
		}

		@Test("Uses the metadata value when logger.category is a .string")
		func stringVariant() {
			let result = OSLogHandler.resolveCategory(
				from: ["logger.category": .string("Network")],
				default: "Default"
			)
			#expect(result.category == "Network")
			#expect(result.usedMetadata == true)
		}

		@Test("Uses the coerced value when logger.category is a .stringConvertible")
		func stringConvertibleVariant() {
			let result = OSLogHandler.resolveCategory(
				from: ["logger.category": .stringConvertible(42)],
				default: "Default"
			)
			#expect(result.category == "42")
			#expect(result.usedMetadata == true)
		}

		@Test("Falls back to default when logger.category is an unsupported variant")
		func unsupportedVariant() {
			let result = OSLogHandler.resolveCategory(
				from: ["logger.category": .array([.string("Network")])],
				default: "Default"
			)
			#expect(result.category == "Default")
			#expect(result.usedMetadata == false)
		}
	}

	// MARK: - metadata(_:strippedAfter:)

	@Suite("metadata(_:strippedAfter:)")
	struct MetadataStripTests {

		@Test("Strips logger.category when the resolution used it")
		func stripsWhenUsed() {
			let input: Logging.Logger.Metadata = [
				LoggerMetadataKey.category: .string("Network"),
				"other": "value"
			]
			let result = OSLogHandler.metadata(
				input,
				strippedAfter: (category: "Network", usedMetadata: true)
			)
			#expect(result[LoggerMetadataKey.category] == nil)
			#expect(result["other"] == "value")
		}

		@Test("Leaves metadata untouched when the resolution did not use it")
		func keepsWhenUnused() {
			let input: Logging.Logger.Metadata = [
				LoggerMetadataKey.category: .array([.string("Custom")]),
				"other": "value"
			]
			let result = OSLogHandler.metadata(
				input,
				strippedAfter: (category: "Default", usedMetadata: false)
			)
			// The key uses a variant we didn't consume; the caller may have
			// other uses for it, so we leave it alone.
			#expect(result[LoggerMetadataKey.category] != nil)
			#expect(result["other"] == "value")
		}
	}

	// MARK: - Routing behaviour through log(...)

	@Suite("log routing")
	struct LogRoutingTests {

		@Test("Defaults route through the construction-time category")
		func defaultCategoryRoutes() {
			let provider = CountingOSLoggerProvider()
			let handler = OSLogHandler(
				osLoggerProvider: provider,
				defaultCategory: "Default"
			)
			handler.log(
				level: .info, message: "msg", metadata: nil,
				source: "TestSource", file: #file, function: #function, line: #line
			)
			#expect(provider.requestedCategories == ["Default"])
		}

		@Test("logger.category in metadata routes through the metadata-derived category")
		func metadataCategoryRoutes() {
			let provider = CountingOSLoggerProvider()
			let handler = OSLogHandler(
				osLoggerProvider: provider,
				defaultCategory: "Default"
			)
			handler.log(
				level: .info, message: "msg",
				metadata: [LoggerMetadataKey.category: .string("Network")],
				source: "TestSource", file: #file, function: #function, line: #line
			)
			#expect(provider.requestedCategories == ["Network"])
		}

		@Test("Repeated logs with the same category make repeated provider lookups")
		func repeatedLogsRepeatedLookups() {
			let provider = CountingOSLoggerProvider()
			let handler = OSLogHandler(
				osLoggerProvider: provider,
				defaultCategory: "Default"
			)
			handler.log(
				level: .info, message: "1", metadata: nil,
				source: "TestSource", file: #file, function: #function, line: #line
			)
			handler.log(
				level: .info, message: "2", metadata: nil,
				source: "TestSource", file: #file, function: #function, line: #line
			)
			// Two calls, same category each time. The provider sees both requests
			// and is responsible for deciding whether to cache.
			#expect(provider.requestedCategories == ["Default", "Default"])
		}

		@Test("CachingOSLoggerProvider returns the cached os.Logger on hit")
		func cachingProviderReusesCachedInstance() {
			let provider = CachingOSLoggerProvider(subsystem: "com.test", seedCategory: "Default")
			let first = provider.osLogger(for: "Custom")
			let second = provider.osLogger(for: "Custom")
			// os.Logger is a struct, so reference identity isn't observable.
			// What we can verify is that the cache only ever has one entry for
			// "Custom" no matter how many times we ask -- the cache key is the
			// category string, so duplicate calls cannot create duplicate entries.
			#expect(provider.cachedCategoriesForTesting == ["Default", "Custom"])
			_ = first; _ = second
		}

		@Test("Round-trip: Logger.categorized routes OSLogHandler via metadata")
		func roundTripThroughLoggerCategorized() {
			// Note: LoggerCache is reference-typed, so the handler copy stored
			// inside the Logger shares its cache with the original `handler`
			// variable. That's how this assertion sees the side effect.
			let handler = OSLogHandler(label: "com.test", category: "Default")
			let logger = Logger(label: "test") { _ in handler }
			let categorized = logger.categorized(TestLogCategory.network)
			categorized.info("hello")

			#expect(handler.cachedCategoriesForTesting.contains("Network"))
		}
	}

	// MARK: - formatMessage

	@Suite("formatMessage")
	struct FormatMessageTests {

		// MARK: Header

		@Test("Includes uppercased level in header")
		func headerIncludesLevel() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .hidden)
			let result = handler.formatMessage(
				level: .warning,
				message: "something happened",
				metadata: [:],
				source: "PyanLogging",
				file: "PyanLogging/OSLogHandler.swift",
				function: "test()",
				line: 1
			)

			#expect(result.hasPrefix("[WARNING]"))
		}

		@Test("Omits source prefix when source matches current module",
			  arguments: [
				("PyanLogging", "PyanLogging/OSLogHandler.swift"),
				("MyModule", "MyModule/File.swift"),
			  ])
		func sourceOmittedWhenMatchingModule(source: String, file: String) {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .hidden)
			let result = handler.formatMessage(
				level: .info,
				message: "hello",
				metadata: [:],
				source: source,
				file: file,
				function: "test()",
				line: 1
			)

			#expect(result == "[INFO] hello")
		}

		@Test("Includes source prefix when source differs from file module")
		func sourceIncludedWhenDifferentModule() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .hidden)
			let result = handler.formatMessage(
				level: .info,
				message: "hello",
				metadata: [:],
				source: "NetworkLayer",
				file: "PyanLogging/OSLogHandler.swift",
				function: "test()",
				line: 1
			)

			#expect(result == "[INFO][NetworkLayer] hello")
		}

		// MARK: Metadata suffix

		@Test("Appends no metadata suffix when metadata is empty")
		func noMetadataSuffixWhenEmpty() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .oneLine)
			let result = handler.formatMessage(
				level: .debug,
				message: "msg",
				metadata: [:],
				source: "PyanLogging",
				file: "PyanLogging/File.swift",
				function: "f()",
				line: 1
			)

			#expect(result == "[DEBUG] msg")
		}

		@Test("Appends formatted metadata on a new line")
		func metadataAppendedOnNewLine() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .oneLine)
			let result = handler.formatMessage(
				level: .info,
				message: "request",
				metadata: ["key": "value"],
				source: "PyanLogging",
				file: "PyanLogging/File.swift",
				function: "f()",
				line: 1
			)

			#expect(result == "[INFO] request\n> key = value")
		}

		// MARK: Full integration

		@Test("Produces expected full output with source, metadata, and multiline style")
		func fullOutputMultiline() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .multiline)
			let result = handler.formatMessage(
				level: .error,
				message: "failed",
				metadata: ["code": "500", "api": "/health"],
				source: "NetworkLayer",
				file: "PyanLogging/File.swift",
				function: "f()",
				line: 1
			)

			#expect(result == "[ERROR][NetworkLayer] failed\n> api = /health\n> code = 500")
		}
	}
}
