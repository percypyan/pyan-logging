//
//  MockLogHandler.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 09/03/2026.
//

#if DEBUG

import Synchronization

/// A `LogHandler` that captures log entries in memory for use in tests.
///
/// `MockLogHandler` records every log call into a shared ``Storage`` instance,
/// allowing test assertions against logged messages, levels, metadata, and
/// sources. The default log level is `.trace` so all messages are captured.
///
/// ```swift
/// let storage = MockLogHandler.Storage()
/// let logger = Logger(label: "test") { label in
///     MockLogHandler(label: label, storage: storage)
/// }
/// logger.info("hello")
/// assert(storage.records.count == 1)
/// ```
///
/// > important: `MockLogHandler` is only available in **Debug** builds.
public struct MockLogHandler: LogHandlerWithCategory {
	/// The backing store where log entries are recorded.
	public let storage: Storage

	/// The logging category label.
	public var category: String

	public var logLevel: Logger.Level = .trace
	public var metadata: Logger.Metadata = [:]
	public var metadataProvider: Logger.MetadataProvider?

	/// Creates a mock log handler.
	///
	/// - Parameters:
	///   - label: The logger label (unused internally but required by `LogHandler`).
	///   - category: An optional category string. Defaults to an empty string.
	///   - storage: The storage instance to record entries into. A new instance is
	///     created by default, but pass a shared one to inspect records from tests.
	public init(label: String, category: String = "", storage: Storage = .init()) {
		self.category = category
		self.storage = storage
	}

	public func log(
		level: Logger.Level,
		message: Logger.Message,
		metadata: Logger.Metadata?,
		source: String,
		file: String,
		function: String,
		line: UInt
	) {
		let finalMetadata = Self.prepareMetadata(
			base: self.metadata,
			provider: metadataProvider,
			explicit: metadata
		)

		storage.records.append(.init(
			level: level,
			message: message,
			metadata: finalMetadata,
			source: source
		))
	}

	public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
		get { metadata[key] }
		set { metadata[key] = newValue }
	}
}

public extension MockLogHandler {
	/// Thread-safe storage that accumulates ``LogEntry`` values from a ``MockLogHandler``.
	///
	/// Share a single `Storage` instance across handlers (or loggers) to collect
	/// all log records in one place for test assertions.
	final class Storage: Sendable {
		private let _records = Mutex<[LogEntry]>([])

		/// The log entries recorded so far, in order of arrival.
		public var records: [LogEntry] {
			get { _records.withLock { $0 } }
			set { _records.withLock { $0 = newValue } }
		}

		/// Creates an empty storage.
		public init() {}
	}
}

public extension MockLogHandler.Storage {
	/// A single captured log record.
	struct LogEntry: Sendable {
		/// The severity level of the log call.
		public let level: Logger.Level
		/// The logged message.
		public let message: Logger.Message
		/// The merged metadata at the time of the log call, or `nil` if none was present.
		public let metadata: Logger.Metadata?
		/// The source module that emitted the log.
		public let source: String
	}
}

extension MockLogHandler {
	static func prepareMetadata(
		base: Logging.Logger.Metadata,
		provider: Logging.Logger.MetadataProvider?,
		explicit: Logging.Logger.Metadata?
	) -> Logging.Logger.Metadata? {
		var metadata = base

		let provided = provider?.get() ?? [:]
		let explicited = explicit ?? [:]

		if !provided.isEmpty {
			metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
		}

		if !explicited.isEmpty {
			metadata.merge(explicited, uniquingKeysWith: { _, explicited in explicited })
		}

		return metadata
	}
}

#endif
