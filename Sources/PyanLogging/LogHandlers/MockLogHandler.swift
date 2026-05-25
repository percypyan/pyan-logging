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
/// keeping both the raw `LogEvent` as the call site passed it and the merged
/// metadata (handler + provider + per-call) that downstream handlers would see.
/// Tests can assert against either.
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
public struct MockLogHandler: LogHandler {
	/// The backing store where log entries are recorded.
	public let storage: Storage

	public var logLevel: Logger.Level = .trace
	public var metadata: Logger.Metadata = [:]
	public var metadataProvider: Logger.MetadataProvider?

	/// Creates a mock log handler.
	///
	/// - Parameters:
	///   - label: The logger label (unused internally but required by `LogHandler`).
	///   - storage: The storage instance to record entries into. A new instance is
	///     created by default, but pass a shared one to inspect records from tests.
	public init(label: String, storage: Storage = .init()) {
		self.storage = storage
	}

	public func log(event: Logging.LogEvent) {
		let finalMetadata = Self.prepareMetadata(
			base: self.metadata,
			provider: metadataProvider,
			explicit: event.metadata
		)
		storage.records.append(.init(event: event, finalMetadata: finalMetadata))
	}

	public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
		get { metadata[key] }
		set { metadata[key] = newValue }
	}
}

public extension MockLogHandler {
	/// Thread-safe storage that accumulates ``Record`` values from a ``MockLogHandler``.
	///
	/// Share a single `Storage` instance across handlers (or loggers) to collect
	/// all log records in one place for test assertions.
	final class Storage: Sendable {
		private let _records = Mutex<[Record]>([])

		/// The records captured so far, in order of arrival.
		public var records: [Record] {
			get { _records.withLock { $0 } }
			set { _records.withLock { $0 = newValue } }
		}

		/// Creates an empty storage.
		public init() {}
	}

	/// A single captured log call.
	struct Record: Sendable {
		/// The `LogEvent` as the call site emitted it.
		public let event: Logging.LogEvent
		/// The metadata after merging handler + provider + per-call metadata,
		/// matching what downstream handlers would see at format time.
		public let finalMetadata: Logging.Logger.Metadata?

		public init(event: Logging.LogEvent, finalMetadata: Logging.Logger.Metadata?) {
			self.event = event
			self.finalMetadata = finalMetadata
		}
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
