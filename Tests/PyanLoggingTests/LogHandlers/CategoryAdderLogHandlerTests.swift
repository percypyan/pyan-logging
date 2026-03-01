//
//  CategoryAdderLogHandler.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

import Testing
@testable import PyanLogging

@Suite("CategoryAdderLogHandler")
struct CategoryAdderLogHandlerTests {

	@Test("Implemented with value type semantics")
	func logHandlerValueSemantics() {
		let handler = CategoryAdderLogHandler(
			category: "UnitTest",
			handler: StreamLogHandler.standardOutput(label: "test")
		)
		checkValueSemanticImplementation(of: handler)
	}

	@Test("Category is injected as logger.category metadata when wrapping a plain handler")
	func categoryInjectedAsMetadata() {
		let inner = StreamLogHandler.standardOutput(label: "test")
		let handler = CategoryAdderLogHandler(category: "Network", handler: inner)

		let provided = handler.metadataProvider?.get()
		#expect(provided?["logger.category"] == "Network")
	}

	@Test("Category setter updates logger.category metadata")
	func categorySetter() {
		let inner = StreamLogHandler.standardOutput(label: "test")
		var handler = CategoryAdderLogHandler(category: "Network", handler: inner)
		handler.category = "Database"

		let provided = handler.metadataProvider?.get()
		#expect(provided?["logger.category"] == "Database")
		#expect(handler.category == "Database")
	}

	@Test("Wrapping a LogHandlerWithCategory forwards category directly")
	func wrappingCategoryHandler() {
		let inner = OSLogHandler(label: "test", category: "Initial")
		let handler = CategoryAdderLogHandler(category: "Forwarded", handler: inner)

		// Category should be forwarded to the inner handler
		#expect(handler.category == "Forwarded")
		// No logger.category in metadata provider since inner handler handles it natively
		let provided = handler.metadataProvider?.get()
		#expect(provided?["logger.category"] == nil)
	}

	@Test("Log calls are forwarded to the wrapped handler")
	func logForwarding() {
		let storage = SpyLogHandler.Storage()
		let spy = SpyLogHandler(storage: storage)
		let handler = CategoryAdderLogHandler(category: "Test", handler: spy)

		handler.log(
			level: .warning,
			message: "something happened",
			metadata: ["extra": "data"],
			source: "TestSource",
			file: #file,
			function: #function,
			line: #line
		)

		#expect(storage.records.count == 1)
		#expect(storage.records.first?.level == .warning)
		#expect(storage.records.first?.message == "something happened")
		#expect(storage.records.first?.metadata?["extra"] == "data")
		#expect(storage.records.first?.source == "TestSource")
	}

	@Test("Metadata subscript is forwarded to wrapped handler")
	func metadataSubscript() {
		let storage = SpyLogHandler.Storage()
		let inner = SpyLogHandler(storage: storage)
		var handler = CategoryAdderLogHandler(category: "Test", handler: inner)

		handler[metadataKey: "request-id"] = "abc-123"
		#expect(handler.handler.metadata["request-id"] == "abc-123")
	}

	@Test("Existing metadata provider is preserved and multiplexed")
	func existingMetadataProviderPreserved() {
		var inner = StreamLogHandler.standardOutput(label: "test")
		inner.metadataProvider = Logger.MetadataProvider { ["custom-key": "custom-value"] }

		let handler = CategoryAdderLogHandler(category: "Network", handler: inner)
		let provided = handler.metadataProvider?.get()

		#expect(provided?["logger.category"] == "Network")
		#expect(provided?["custom-key"] == "custom-value")
	}
}
