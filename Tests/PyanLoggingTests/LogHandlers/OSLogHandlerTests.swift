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
