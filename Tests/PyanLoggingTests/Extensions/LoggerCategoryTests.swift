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

	@Test("Attaches logger.category to the logger's metadata")
	func attachesCategoryMetadata() {
		var logger = Logger(label: "test")
		logger.handler = SpyLogHandler(storage: .init())

		let categorized = logger.categorized(TestLogCategory.network)

		#expect(categorized[metadataKey: "logger.category"] == "Network")
	}

	@Test("Does not mutate the original logger")
	func originalNotMutated() {
		var logger = Logger(label: "test")
		logger.handler = SpyLogHandler(storage: .init())

		_ = logger.categorized(TestLogCategory.network)

		#expect(logger[metadataKey: "logger.category"] == nil)
	}

	@Test("Uses LogCategory.label as category value")
	func usesLabelProperty() {
		var logger = Logger(label: "test")
		logger.handler = SpyLogHandler(storage: .init())

		let custom = CustomLabelCategory(label: "My Custom Category")
		let categorized = logger.categorized(custom)

		#expect(categorized[metadataKey: "logger.category"] == "My Custom Category")
	}
}
