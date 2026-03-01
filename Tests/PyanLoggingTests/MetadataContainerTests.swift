//
//  MetadataContainerTests.swift
//  PyanLogging
//
//  Created by Claude on 04/03/2026.
//

import Testing
@testable import PyanLogging

@Suite("MetadataContainer")
struct MetadataContainerTests {

	@Test("Init with no arguments creates empty metadata")
	func initEmpty() {
		let container = MetadataContainer<FlatMetadataKey>()
		#expect(container.metadata == [:])
	}

	@Test("Init with initial metadata preserves values")
	func initWithMetadata() {
		let initial: Logger.Metadata = ["userId": "42", "sessionId": "abc"]
		let container = MetadataContainer<FlatMetadataKey>(initial)
		#expect(container.metadata == initial)
	}

	@Test("Flat key update stores string value")
	func flatKeyUpdate() {
		let container = MetadataContainer<FlatMetadataKey>()
		container.update(.userId, value: "user-1")
		#expect(container.metadata["userId"] == "user-1")
	}

	@Test("Flat key removal with nil")
	func flatKeyRemoval() {
		let container = MetadataContainer<FlatMetadataKey>()
		container.update(.userId, value: "user-1")
		container.update(.userId, value: nil as String?)
		#expect(container.metadata["userId"] == nil)
	}

	@Test("Chaining updates returns self and accumulates values")
	func chainingUpdates() {
		let container = MetadataContainer<FlatMetadataKey>()
		container
			.update(.userId, value: "user-1")
			.update(.sessionId, value: "session-1")

		#expect(container.metadata["userId"] == "user-1")
		#expect(container.metadata["sessionId"] == "session-1")
	}

	@Test("Nested key with separator creates nested dictionaries")
	func nestedKeySeparator() {
		let container = MetadataContainer<NestedMetadataKey>()
		container.update(.userProfileName, value: .string("Alice"))

		// rawValue "user.profile.name" with separator "." -> ["user": ["profile": ["name": "Alice"]]]
		let expected: Logger.Metadata = [
			"user": [
				"profile": [
					"name": "Alice"
				]
			]
		]
		#expect(container.metadata == expected)
	}

	@Test("Nested key removal with nil")
	func nestedKeyRemoval() {
		let container = MetadataContainer<NestedMetadataKey>()
		container.update(.userProfileName, value: .string("Alice"))
		container.update(.userProfileName, value: nil as Logger.Metadata.Value?)

		// The nested path should have nil at the leaf
		let expected: Logger.Metadata = [
			"user": [
				"profile": [:]
			]
		]
		#expect(container.metadata == expected)
	}

	@Test("Prefix is prepended to key")
	func prefixedKey() {
		let container = MetadataContainer<PrefixedMetadataKey>()
		container.update(.userId, value: "user-1")
		#expect(container.metadata["app.userId"] == "user-1")
	}

	@Test("Provider returns current metadata snapshot")
	func providerReturnsMetadata() {
		let container = MetadataContainer<FlatMetadataKey>()
		container.update(.userId, value: "user-1")

		let provided = container.provider.get()
		#expect(provided == container.metadata)
	}

	@Test("Dictionary convenience update")
	func dictionaryConvenience() {
		let container = MetadataContainer<FlatMetadataKey>()
		let dict: Logger.Metadata = ["nested": "value"]
		container.update(.userId, value: dict)
		#expect(container.metadata["userId"] == .dictionary(dict))
	}

	@Test("Array convenience update")
	func arrayConvenience() {
		let container = MetadataContainer<FlatMetadataKey>()
		let array: [Logger.MetadataValue] = ["a", "b"]
		container.update(.userId, value: array)
		#expect(container.metadata["userId"] == .array(array))
	}

	@Test("CustomStringConvertible convenience update")
	func customStringConvertibleConvenience() {
		let container = MetadataContainer<FlatMetadataKey>()
		container.update(.userId, value: 42)
		#expect(container.metadata["userId"] == .stringConvertible(42))
	}
}
