//
//  OSLogHandler.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

import Testing
@testable import PyanLogging

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
			let provider = Logger.MetadataProvider { ["provided": "dynamic"] }
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

	// MARK: - Routing behaviour through log(...)

	@Suite("log routing")
	struct LogRoutingTests {

		@Test("Defaults route through the construction-time category")
		func defaultCategoryRoutesThroughCache() {
			let handler = OSLogHandler(label: "com.test", category: "Default")
			handler.log(
				level: .info, message: "msg", metadata: nil,
				source: "TestSource", file: #file, function: #function, line: #line
			)
			#expect(handler.cachedCategoriesForTesting == ["Default"])
		}

		@Test("logger.category in metadata routes through the metadata-derived category")
		func metadataCategoryRoutesThroughCache() {
			let handler = OSLogHandler(label: "com.test", category: "Default")
			handler.log(
				level: .info, message: "msg",
				metadata: ["logger.category": .string("Network")],
				source: "TestSource", file: #file, function: #function, line: #line
			)
			#expect(handler.cachedCategoriesForTesting == ["Default", "Network"])
		}

		@Test("Successive logs with the same category reuse the same os.Logger")
		func reusesCachedOsLogger() {
			let handler = OSLogHandler(label: "com.test", category: "Default")
			let first = handler.osLogger(for: "Custom")
			let second = handler.osLogger(for: "Custom")
			// os.Logger is a struct; identity isn't directly observable, but the
			// cache size proves only one was created.
			#expect(handler.cachedCategoriesForTesting == ["Default", "Custom"])
			_ = first; _ = second
		}

		@Test("Round-trip: Logger.categorized routes OSLogHandler via metadata")
		func roundTripThroughLoggerCategorized() {
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
