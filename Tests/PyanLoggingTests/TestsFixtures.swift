//
//  TestsFixtures.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

import Testing
@testable import PyanLogging

// MARK: - Value Semantics Helper

// This test needs to pass for all LogHandler implementations.
// See swift-log package documentation for details:
// https://swiftpackageindex.com/apple/swift-log/1.10.1/documentation/logging/implementingaloghandler#Implement-with-value-type-semantics
func checkValueSemanticImplementation(of handler: any LogHandler) {
	var logger1 = Logger(label: "first logger")
	logger1.handler = handler
	logger1.logLevel = .debug
	logger1[metadataKey: "only-on"] = "first"

	var logger2 = logger1
	logger2.logLevel = .error                  // Must not affect logger1
	logger2[metadataKey: "only-on"] = "second" // Must not affect logger1

	// These expectations must pass
	#expect(logger1.logLevel == .debug)
	#expect(logger2.logLevel == .error)
	#expect(logger1[metadataKey: "only-on"] == "first")
	#expect(logger2[metadataKey: "only-on"] == "second")
}

// MARK: - Spy LogHandler

/// A LogHandler that records all log calls for verification in tests.
struct SpyLogHandler: LogHandler {
	final class Storage: @unchecked Sendable {
		var records: [(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String)] = []
	}

	let storage: Storage

	var logLevel: Logger.Level = .trace
	var metadata: Logger.Metadata = [:]
	var metadataProvider: Logger.MetadataProvider?

	init(storage: Storage) {
		self.storage = storage
	}

	func log(
		level: Logger.Level,
		message: Logger.Message,
		metadata: Logger.Metadata?,
		source: String,
		file: String,
		function: String,
		line: UInt
	) {
		storage.records.append((level: level, message: message, metadata: metadata, source: source))
	}

	subscript(metadataKey key: String) -> Logger.Metadata.Value? {
		get { metadata[key] }
		set { metadata[key] = newValue }
	}
}

// MARK: - Spy LogHandlerWithCategory

/// A LogHandler that conforms to LogHandlerWithCategory for testing the direct-category path.
struct SpyCategoryLogHandler: LogHandlerWithCategory {
	let storage: SpyLogHandler.Storage

	var category: String
	var logLevel: Logger.Level = .trace
	var metadata: Logger.Metadata = [:]
	var metadataProvider: Logger.MetadataProvider?

	init(label: String, category: String = "", storage: SpyLogHandler.Storage = .init()) {
		self.category = category
		self.storage = storage
	}

	func log(
		level: Logger.Level,
		message: Logger.Message,
		metadata: Logger.Metadata?,
		source: String,
		file: String,
		function: String,
		line: UInt
	) {
		storage.records.append((level: level, message: message, metadata: metadata, source: source))
	}

	subscript(metadataKey key: String) -> Logger.Metadata.Value? {
		get { metadata[key] }
		set { metadata[key] = newValue }
	}
}

// MARK: - Test LogCategory

enum TestLogCategory: String, LogCategory {
	case network
	case database
	case ui
}

struct CustomLabelCategory: LogCategory {
	let label: String
}

// MARK: - Test MetadataKey

enum FlatMetadataKey: String, MetadataKey {
	case userId = "userId"
	case sessionId = "sessionId"
}

enum PrefixedMetadataKey: String, MetadataKey {
	case userId = "userId"

	var prefix: String? { "app" }
}

enum NestedMetadataKey: String, MetadataKey {
	case userProfileName = "user.profile.name"
	case userProfileAge = "user.profile.age"
	case userEmail = "user.email"

	var nestedMetadataSeparator: String? { "." }
}

// MARK: - Test LoggerAttachable

struct TestAttachable: LoggerAttachable {
	let logMetadata: Logger.Metadata
}
