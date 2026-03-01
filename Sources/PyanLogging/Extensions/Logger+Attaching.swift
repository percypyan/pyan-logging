//
//  Logger+Attaching.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

public extension Logger {
	/// Returns a copy of this logger with the attachable's metadata nested under the given key.
	///
	/// - Parameters:
	///   - key: The metadata key under which the attachable's metadata dictionary is stored.
	///   - attachable: The value whose ``LoggerAttachable/logMetadata``
	///     will be added to the returned logger.
	/// - Returns: A new `Logger` that includes the additional metadata.
	func attaching(key: String, _ attachable: LoggerAttachable) -> Logger {
		var logger = self
		logger[metadataKey: key] = .dictionary(attachable.logMetadata)
		return logger
	}
}
