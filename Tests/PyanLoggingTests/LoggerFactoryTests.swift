//
//  LoggerFactory.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

import Synchronization
import Testing
@testable import PyanLogging

@Suite("LoggerFactory")
struct LoggerFactoryTests {

	@Test("Factory attaches logger.category metadata to produced loggers")
	func factoryAttachesCategoryMetadata() {
		let factory = LoggerFactory<TestLogCategory>(label: "com.test.app") { label in
			SpyLogHandler(storage: .init())
		}
		let logger = factory.logger(for: .network)

		#expect(logger[metadataKey: "logger.category"] == "Network")
	}

	@Test("Factory with metadata-accepting handler factory invokes the closure")
	func handlerFactoryWithMetadata() {
		let receivedLabel = Mutex<String?>(nil)
		let factory = LoggerFactory<TestLogCategory>(label: "com.test.app") { label, provider in
			receivedLabel.withLock { $0 = label }
			return SpyLogHandler(storage: .init())
		}
		_ = factory.logger(for: .ui)

		#expect(receivedLabel.withLock { $0 } == "com.test.app")
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

		#expect(networkLogger[metadataKey: "logger.category"] == "Network")
		#expect(dbLogger[metadataKey: "logger.category"] == "Database")
	}
}
