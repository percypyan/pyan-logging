//
//  MetadataFormatterTests.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 20/05/2026.
//

import Testing
@testable import PyanLogging

@Suite("MetadataFormatter")
struct MetadataFormatterTests {
	private let sampleMetadata: Logger.Metadata = [
		"userId": "42",
		"requestId": "abc-123"
	]

	// MARK: - Empty metadata

	@Test("Returns nil when metadata is empty regardless of style", arguments: [
		MetadataFormatter.MetadataStyle.oneLine,
		.multiline,
		.dictionary,
		.hidden
	])
	func emptyMetadata(style: MetadataFormatter.MetadataStyle) {
		#expect(MetadataFormatter(style: style).string(for: [:]) == nil)
	}

	// MARK: - oneLine

	@Test("Formats metadata on a single pipe-separated line")
	func oneLineFormat() {
		let result = MetadataFormatter(style: .oneLine).string(for: sampleMetadata)
		#expect(result == "> requestId = abc-123 | userId = 42")
	}

	// MARK: - multiline

	@Test("Formats each metadata pair on its own line")
	func multilineFormat() {
		let result = MetadataFormatter(style: .multiline).string(for: sampleMetadata)
		#expect(result == "> requestId = abc-123\n> userId = 42")
	}

	// MARK: - dictionary

	@Test("Uses the metadata dictionary description")
	func dictionaryFormat() {
		let result = MetadataFormatter(style: .dictionary).string(for: ["userId": "42"])
		#expect(result == """
		[
			"userId": "42"
		]
		""")
	}

	// MARK: - hidden

	@Test("Returns nil when style is hidden")
	func hiddenFormat() {
		let result = MetadataFormatter(style: .hidden).string(for: sampleMetadata)
		#expect(result == nil)
	}

	// MARK: - Nested metadata

	@Test("Flattens nested metadata before formatting with oneLine")
	func nestedMetadataOneLine() {
		let nested: Logger.Metadata = [
			"user": .dictionary(["name": "Alice", "id": "1"])
		]
		let result = MetadataFormatter(style: .oneLine).string(for: nested)
		#expect(result == "> user.id = 1 | user.name = Alice")
	}

	@Test("Flattens nested metadata before formatting with multiline")
	func nestedMetadataMultiline() {
		let nested: Logger.Metadata = [
			"user": .dictionary(["name": "Alice", "id": "1"])
		]
		let result = MetadataFormatter(style: .multiline).string(for: nested)
		#expect(result == "> user.id = 1\n> user.name = Alice")
	}

	@Test("Preserves nested structure when formatting with dictionary")
	func notFlatteningMetadataDictionary() {
		let nested: Logger.Metadata = [
			"user": .dictionary(["name": "Alice"])
		]
		let result = MetadataFormatter(style: .dictionary).string(for: nested)
		#expect(result == """
		[
			"user": [
				"name": "Alice"
			]
		]
		""")
	}
}
