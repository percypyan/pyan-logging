//
//  LoggerAttachingTests.swift
//  PyanLogging
//
//  Created by Claude on 04/03/2026.
//

import Testing
@testable import PyanLogging

@Suite("Logger.attaching")
struct LoggerAttachingTests {

	@Test("Attaching adds metadata nested under key")
	func attachingAddsMetadata() {
		let attachable = TestAttachable(logMetadata: ["id": "42", "type": "premium"])
		let logger = Logger(label: "test")
		let enriched = logger.attaching(key: "user", attachable)

		#expect(enriched[metadataKey: "user"] == .dictionary(["id": "42", "type": "premium"]))
	}

	@Test("Original logger is not mutated")
	func originalNotMutated() {
		let attachable = TestAttachable(logMetadata: ["id": "42"])
		let logger = Logger(label: "test")
		_ = logger.attaching(key: "user", attachable)

		#expect(logger[metadataKey: "user"] == nil)
	}
}
