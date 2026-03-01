//
//  LoggerMetadata+FlatteningTests.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

import Testing
@testable import PyanLogging

@Suite("Logger.Metadata's Flattening extension")
struct LoggerMetadataFlatteningExtensionTests {

	@Test("Simple nested metadata")
	func simpleNestedMetadata() async throws {
		let metadata: Logger.Metadata = [
			"first": [
				"second": "value1",
				"secondToThird": [
					"third": "deep",
					"thirdTofourth": [
						"fourth": "realDepth"
					]
				]
			],
			"first.level": .stringConvertible("hello")
		]

		#expect(
			metadata.flattening(
				nestedDictionaryPathRepresentation: .dot,
				nestedArrayPathRepresentation: .brackets
			) == [
				"first.second": "value1",
				"first.secondToThird.third": "deep",
				"first.secondToThird.thirdTofourth.fourth": "realDepth",
				"first.level": .stringConvertible("hello")
			]
		)
	}

	@Test("Array and dictionary nested metadata")
	func nestedMetadata() async throws {
		let metadata: Logger.Metadata = [
			"first": [
				"second": ["value1", "value2", .stringConvertible("value3")]
			],
			"first.level": "hello",
			"first.nestedArray": ["a1", ["a2", "a3"]],
			"first.nestedDict": ["d1", ["nested": "d3"]],
			"first.nestedDict2": ["nested2": ["2d1", "2d2"]],
		]

		#expect(
			metadata.flattening(
				nestedDictionaryPathRepresentation: .dot,
				nestedArrayPathRepresentation: .brackets
			) == [
				"first.second[0]": "value1",
				"first.second[1]": "value2",
				"first.second[2]": .stringConvertible("value3"),
				"first.level": "hello",
				"first.nestedArray[0]": "a1",
				"first.nestedArray[1][0]": "a2",
				"first.nestedArray[1][1]": "a3",
				"first.nestedDict[0]": "d1",
				"first.nestedDict[1].nested": "d3",
				"first.nestedDict2.nested2[0]": "2d1",
				"first.nestedDict2.nested2[1]": "2d2",
			]
		)
	}

	@Test("NestedDictionaryPathRepresentation", arguments: [
		NestedPathRepresentation.dot,
		.brackets,
		.chevrons,
		.curlyBraces,
		.parentheses,
		.custom("+"),
		.custom("_"),
		.customWrapping(opening: "/", closing: "\\")
	])
	func nestedDictionaryPathRepresentationOptionMetadata(_ option: NestedPathRepresentation) async throws {
		let metadata: Logger.Metadata = [
			"first.level": [
				"second": [
					"third",
					["fourth": "value"]
				]
			]
		]
		let o = option.opening
		let c = option.closing

		#expect(
			metadata.flattening(
				nestedDictionaryPathRepresentation: option,
				nestedArrayPathRepresentation: .brackets
			) == [
				"first.level\(o)second\(c)[0]": "third",
				"first.level\(o)second\(c)[1]\(o)fourth\(c)": "value"
			]
		)
	}

	@Test("NestedArrayPathRepresentation", arguments: [
		NestedPathRepresentation.dot,
		.brackets,
		.chevrons,
		.curlyBraces,
		.parentheses,
		.custom("+"),
		.custom("_"),
		.customWrapping(opening: "/", closing: "\\")
	])
	func nestedArrayPathRepresentationOptionMetadata(_ option: NestedPathRepresentation) async throws {
		let metadata: Logger.Metadata = [
			"first.level": [
				"second": [
					"third",
					["fourth": "value"]
				]
			]
		]
		let o = option.opening
		let c = option.closing

		#expect(
			metadata.flattening(
				nestedDictionaryPathRepresentation: .dot,
				nestedArrayPathRepresentation: option
			) == [
				"first.level.second\(o)0\(c)": "third",
				"first.level.second\(o)1\(c).fourth": "value"
			]
		)
	}
}
