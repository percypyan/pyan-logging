//
//  LoggerFactory.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

import Testing
@testable import PyanLogging

@Suite("LoggerFactory")
struct LoggerFactoryTests {

	@Test("Factory with handler factory wraps non-category handler in CategoryAdderLogHandler")
	func handlerFactoryWrapsNonCategoryHandler() {
		let factory = LoggerFactory<TestLogCategory>(label: "com.test.app") { label in
			SpyLogHandler(storage: .init())
		}
		let logger = factory.logger(for: .network)

		let handler = logger.handler as? CategoryAdderLogHandler
		#expect(handler != nil)
		#expect(handler?.category == "Network")
	}

	@Test("Factory with handler factory sets category directly on LogHandlerWithCategory")
	func handlerFactoryDirectCategory() {
		let factory = LoggerFactory<TestLogCategory>(label: "com.test.app") { label in
			SpyCategoryLogHandler(label: label)
		}
		let logger = factory.logger(for: .database)

		let handler = logger.handler as? SpyCategoryLogHandler
		#expect(handler != nil)
		#expect(handler?.category == "Database")
	}

	@Test("Factory with metadata-accepting handler factory invokes the closure")
	func handlerFactoryWithMetadata() {
		var receivedLabel: String?
		let factory = LoggerFactory<TestLogCategory>(label: "com.test.app") { label, provider in
			receivedLabel = label
			return SpyLogHandler(storage: .init())
		}
		_ = factory.logger(for: .ui)

		#expect(receivedLabel == "com.test.app")
	}

	@Test("Factory with metadata provider attaches it to the logger")
	func factoryWithMetadataProvider() {
		let provider = Logger.MetadataProvider { ["env": "test"] }
		let factory = LoggerFactory<TestLogCategory>(label: "com.test.app", metadataProvider: provider)
		let logger = factory.logger(for: .network)

		let provided = logger.handler.metadataProvider?.get()
		#expect(provided?["env"] == "test")
	}

	@Test("Category label uses LogCategory.label for different categories")
	func categoryLabelFromConformance() {
		let factory = LoggerFactory<TestLogCategory>(label: "com.test.app") { label in
			SpyLogHandler(storage: .init())
		}

		let networkLogger = factory.logger(for: .network)
		let dbLogger = factory.logger(for: .database)

		#expect((networkLogger.handler as? CategoryAdderLogHandler)?.category == "Network")
		#expect((dbLogger.handler as? CategoryAdderLogHandler)?.category == "Database")
	}
}
