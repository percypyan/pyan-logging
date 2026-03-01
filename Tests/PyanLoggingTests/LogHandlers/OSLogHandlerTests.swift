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

	// MARK: - formatMetadata

	@Suite("formatMetadata")
	struct FormatMetadataTests {
		private let sampleMetadata: Logger.Metadata = [
			"userId": "42",
			"requestId": "abc-123"
		]

		// MARK: nil metadata

		@Test("Returns nil when metadata is nil regardless of style", arguments: [
			OSLogHandler.MetadataStyle.oneLine,
			.multiline,
			.dictionary,
			.hidden
		])
		func nilMetadata(style: OSLogHandler.MetadataStyle) {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: style)
			#expect(handler.formatMetadata(metadata: nil) == nil)
		}

		// MARK: Empty metadata

		@Test("Returns nil when metadata are empty regardless of style", arguments: [
			OSLogHandler.MetadataStyle.oneLine,
			.multiline,
			.dictionary,
			.hidden
		])
		func emptyMetadata(style: OSLogHandler.MetadataStyle) {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: style)
			#expect(handler.formatMetadata(metadata: [:]) == nil)
		}

		// MARK: oneLine

		@Test("Formats metadata on a single pipe-separated line")
		func oneLineFormat() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .oneLine)
			let result = handler.formatMetadata(metadata: sampleMetadata)

			#expect(result == "> requestId = abc-123 | userId = 42")
		}

		@Test("Default style is oneLine")
		func defaultStyleIsOneLine() {
			let handler = OSLogHandler(label: "test", category: "Test")
			let result = handler.formatMetadata(metadata: sampleMetadata)

			#expect(result == "> requestId = abc-123 | userId = 42")
		}

		// MARK: multiline

		@Test("Formats each metadata pair on its own line")
		func multilineFormat() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .multiline)
			let result = handler.formatMetadata(metadata: sampleMetadata)

			#expect(result == "> requestId = abc-123\n> userId = 42")
		}

		// MARK: dictionary

		@Test("Uses the metadata dictionary description")
		func dictionaryFormat() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .dictionary)
			let result = handler.formatMetadata(metadata: ["userId": "42"])

			#expect(result == """
			[
				"userId": "42"
			]
			""")
		}

		// MARK: hidden

		@Test("Returns nil when style is hidden")
		func hiddenFormat() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .hidden)
			let result = handler.formatMetadata(metadata: sampleMetadata)

			#expect(result == nil)
		}

		// MARK: Nested metadata

		@Test("Flattens nested metadata before formatting with oneLine")
		func nestedMetadataOneLine() {
			let nested: Logger.Metadata = [
				"user": .dictionary(["name": "Alice", "id": "1"])
			]
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .oneLine)
			let result = handler.formatMetadata(metadata: nested)

			#expect(result == "> user.id = 1 | user.name = Alice")
		}

		@Test("Flattens nested metadata before formatting with multiline")
		func nestedMetadataMultiline() {
			let nested: Logger.Metadata = [
				"user": .dictionary(["name": "Alice", "id": "1"])
			]
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .multiline)
			let result = handler.formatMetadata(metadata: nested)

			#expect(result == "> user.id = 1\n> user.name = Alice")
		}

		@Test("Is not flattening nested metadata before formatting with dictionary")
		func notFlatteningMetadataDictionary() {
			let nested: Logger.Metadata = [
				"user": .dictionary(["name": "Alice"])
			]
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .dictionary)
			let result = handler.formatMetadata(metadata: nested)

			#expect(result == """
			[
				"user": [
					"name": "Alice"
				]
			]
			""")
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
				metadata: nil,
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
				metadata: nil,
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
				metadata: nil,
				source: "NetworkLayer",
				file: "PyanLogging/OSLogHandler.swift",
				function: "test()",
				line: 1
			)

			#expect(result == "[INFO][NetworkLayer] hello")
		}

		// MARK: Metadata suffix

		@Test("Appends no metadata suffix when metadata is nil")
		func noMetadataSuffixWhenNil() {
			let handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .oneLine)
			let result = handler.formatMessage(
				level: .debug,
				message: "msg",
				metadata: nil,
				source: "PyanLogging",
				file: "PyanLogging/File.swift",
				function: "f()",
				line: 1
			)

			#expect(result == "[DEBUG] msg")
		}

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

		// MARK: Metadata merging

		@Test("Merges handler metadata with explicit metadata")
		func mergesHandlerAndExplicitMetadata() {
			var handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .oneLine)
			handler.metadata = ["handler": "base"]

			let result = handler.formatMessage(
				level: .info,
				message: "merged",
				metadata: ["explicit": "extra"],
				source: "PyanLogging",
				file: "PyanLogging/File.swift",
				function: "f()",
				line: 1
			)

			#expect(result.contains("handler = base"))
			#expect(result.contains("explicit = extra"))
		}

		@Test("Explicit metadata overrides handler metadata for same key")
		func explicitOverridesHandler() {
			var handler = OSLogHandler(label: "test", category: "Test", metadataStyle: .oneLine)
			handler.metadata = ["key": "from-handler"]

			let result = handler.formatMessage(
				level: .info,
				message: "override",
				metadata: ["key": "from-explicit"],
				source: "PyanLogging",
				file: "PyanLogging/File.swift",
				function: "f()",
				line: 1
			)

			#expect(result.contains("key = from-explicit"))
			#expect(!result.contains("from-handler"))
		}

		@Test("Merges provider metadata into output")
		func mergesProviderMetadata() {
			let handler = OSLogHandler(
				label: "test",
				category: "Test",
				metadataStyle: .oneLine,
				metadataProvider: .init { ["provided": "dynamic"] }
			)

			let result = handler.formatMessage(
				level: .info,
				message: "with-provider",
				metadata: nil,
				source: "PyanLogging",
				file: "PyanLogging/File.swift",
				function: "f()",
				line: 1
			)

			#expect(result.contains("provided = dynamic"))
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
