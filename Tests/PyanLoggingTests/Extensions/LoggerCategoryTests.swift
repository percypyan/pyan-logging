//
//  LoggerCategoryTests.swift
//  PyanLogging
//
//  Created by Claude on 04/03/2026.
//

import Testing
@testable import PyanLogging

@Suite("Logger.categorized")
struct LoggerCategoryTests {

	@Test("Wraps non-category handler in CategoryAdderLogHandler")
	func wrapsNonCategoryHandler() {
		var logger = Logger(label: "test")
		logger.handler = SpyLogHandler(storage: .init())

		let categorized = logger.categorized(TestLogCategory.network)

		let handler = categorized.handler as? CategoryAdderLogHandler
		#expect(handler != nil)
		#expect(handler?.category == "Network")
	}

	@Test("Sets category directly on LogHandlerWithCategory handler")
	func directCategoryOnConformingHandler() {
		var logger = Logger(label: "test")
		logger.handler = SpyCategoryLogHandler(label: "test")

		let categorized = logger.categorized(TestLogCategory.database)

		let handler = categorized.handler as? SpyCategoryLogHandler
		#expect(handler != nil)
		#expect(handler?.category == "Database")
	}

	@Test("Does not mutate the original logger")
	func originalNotMutated() {
		var logger = Logger(label: "test")
		logger.handler = SpyLogHandler(storage: .init())

		_ = logger.categorized(TestLogCategory.network)

		#expect(logger.handler is SpyLogHandler)
	}

	@Test("Uses LogCategory.label as category value")
	func usesLabelProperty() {
		var logger = Logger(label: "test")
		logger.handler = SpyLogHandler(storage: .init())

		let custom = CustomLabelCategory(label: "My Custom Category")
		let categorized = logger.categorized(custom)

		let handler = categorized.handler as? CategoryAdderLogHandler
		#expect(handler?.category == "My Custom Category")
	}
}
