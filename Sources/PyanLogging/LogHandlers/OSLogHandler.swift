//
//  OSLogHandler.swift
//  PyanLogger
//
//  Created by Perceval Archimbaud on 01/03/2026.
//

#if canImport(os)

import Foundation
import os
import Synchronization

/// A `LogHandler` that routes swift-log messages to Apple's unified logging system (`os.Logger`).
///
/// The handler's subsystem is taken from `label`. The category is resolved per
/// log call: when the merged metadata contains a `logger.category` entry
/// (either `.string` or `.stringConvertible`), it routes to an `os.Logger`
/// configured with that category and removes the key from the formatted
/// metadata. Otherwise, it falls back to the default category supplied at
/// construction.
///
/// `os.Logger` instances are cached per category so repeated logs reuse them.
///
/// Log levels are translated to the corresponding `os.Logger` methods
/// (e.g. `.warning` maps to `osLogger.warning`).
///
/// Log output is by default formatted as:
/// ```
/// [LEVEL][Source] Message
/// > key = value | key = value
/// ```
///
/// The metadata layout can be customized by passing a ``MetadataFormatter/MetadataStyle`` at
/// initialization. The default style is ``MetadataFormatter/MetadataStyle/oneLine``.
///
/// Metadata from the handler, its provider, and per-message metadata are merged
/// and flattened before being appended.
public struct OSLogHandler: LogHandler {
	private let label: String
	private let defaultCategory: String
	private let loggerCache: LoggerCache
	private let metadataStyle: MetadataFormatter.MetadataStyle

	public var logLevel: Logging.Logger.Level = .info
	public var metadata: Logging.Logger.Metadata = [:]
	public var metadataProvider: Logging.Logger.MetadataProvider?

	/// Creates a handler that logs to the unified logging system.
	///
	/// - Parameters:
	///   - label: The subsystem identifier (typically a reverse-DNS string).
	///   - category: The default category, used when a log call's metadata
	///     does not carry a `logger.category` entry.
	///   - metadataStyle: The style used to format metadata in the log output.
	///   - metadataProvider: An optional provider for dynamic metadata.
	public init(
		label: String,
		category: String,
		metadataStyle: MetadataFormatter.MetadataStyle = .oneLine,
		metadataProvider: Logging.Logger.MetadataProvider? = nil
	) {
		self.label = label
		self.defaultCategory = category
		self.metadataStyle = metadataStyle
		self.metadataProvider = metadataProvider
		self.loggerCache = LoggerCache(
			seed: [category: os.Logger(subsystem: label, category: category)]
		)
	}

	public func log(
		level: Logging.Logger.Level,
		message: Logging.Logger.Message,
		metadata: Logging.Logger.Metadata?,
		source: String,
		file: String,
		function: String,
		line: UInt
	) {
		// Merge handler, provider, and per-message metadata.
		let merged = Self.prepareMetadata(
			base: self.metadata,
			provider: metadataProvider,
			explicit: metadata
		) ?? [:]

		// Resolve the routing category from metadata, falling back to the default.
		let resolution = Self.resolveCategory(from: merged, default: defaultCategory)

		// Strip logger.category from the formatted output only when it drove routing.
		var formattedMetadata = merged
		if resolution.usedMetadata {
			formattedMetadata.removeValue(forKey: Self.categoryMetadataKey)
		}

		let osLogger = osLogger(for: resolution.category)
		let text = formatMessage(
			level: level,
			message: message,
			metadata: formattedMetadata,
			source: source,
			file: file,
			function: function,
			line: line
		)

		// Let os.Logger do the level mapping for us.
		switch level {
		case .trace: osLogger.trace("\(text, privacy: .public)")
		case .debug: osLogger.debug("\(text, privacy: .public)")
		case .info: osLogger.info("\(text, privacy: .public)")
		case .notice: osLogger.notice("\(text, privacy: .public)")
		case .warning: osLogger.warning("\(text, privacy: .public)")
		case .error: osLogger.error("\(text, privacy: .public)")
		case .critical: osLogger.critical("\(text, privacy: .public)")
		}
	}

	public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
		get { metadata[key] }
		set { metadata[key] = newValue }
	}
}

extension OSLogHandler {
	/// The reserved metadata key used to drive `os.Logger` category routing.
	static let categoryMetadataKey = "logger.category"

	/// Resolves the category to route to for a given merged-metadata snapshot.
	///
	/// Accepts both `.string` and `.stringConvertible` variants for the
	/// ``categoryMetadataKey`` entry; any other variant (or absent key) yields
	/// the default category and `usedMetadata == false`.
	static func resolveCategory(
		from metadata: Logging.Logger.Metadata,
		default defaultCategory: String
	) -> (category: String, usedMetadata: Bool) {
		guard let value = metadata[categoryMetadataKey] else {
			return (defaultCategory, false)
		}
		switch value {
		case .string(let string):
			return (string, true)
		case .stringConvertible(let convertible):
			return (String(describing: convertible), true)
		default:
			return (defaultCategory, false)
		}
	}

	/// Fetches a cached `os.Logger` for the given category, creating one on miss.
	func osLogger(for category: String) -> os.Logger {
		loggerCache.logger(for: category) {
			os.Logger(subsystem: label, category: category)
		}
	}
}

extension OSLogHandler {
	/// Reference-typed memoization of `os.Logger` instances keyed by category.
	///
	/// `Mutex` is `~Copyable` and so cannot live directly in a `Copyable`
	/// struct; wrapping it in a final class keeps `OSLogHandler` a value type
	/// while still allowing the cache to be shared between copies. The cache
	/// only stores derived state, so sharing is benign.
	final class LoggerCache: Sendable {
		private let storage: Mutex<[String: os.Logger]>

		init(seed: [String: os.Logger]) {
			self.storage = Mutex(seed)
		}

		func logger(for category: String, make: () -> os.Logger) -> os.Logger {
			storage.withLock { cache in
				if let cached = cache[category] {
					return cached
				}
				let made = make()
				cache[category] = made
				return made
			}
		}

		#if DEBUG
		/// The set of categories present in the cache. Test-only.
		var cachedCategoriesForTesting: Set<String> {
			storage.withLock { Set($0.keys) }
		}
		#endif
	}
}

#if DEBUG
extension OSLogHandler {
	/// The set of categories whose `os.Logger` instances have been cached.
	/// Test-only.
	var cachedCategoriesForTesting: Set<String> {
		loggerCache.cachedCategoriesForTesting
	}
}
#endif

extension OSLogHandler {
	func formatMessage(
		level: Logging.Logger.Level,
		message: Logging.Logger.Message,
		metadata: Logging.Logger.Metadata,
		source: String,
		file: String,
		function: String,
		line: UInt
	) -> String {
		// Other relevant info are generated by OSLog directly:
		// timestamp, bundle, library (that's matching source)

		// Header
		let sourcePrefix = source != Self.currentModule(fileID: file) ? "[\(source)]" : ""
		let header = "[\(level.rawValue.uppercased())]\(sourcePrefix)"

		// Metadata
		let formatter = MetadataFormatter(style: metadataStyle)
		let metadataString = formatter.string(for: metadata)
		let metadataSuffix = metadataString != nil ? "\n\(metadataString!)" : ""

		return "\(header) \(message)\(metadataSuffix)"
	}

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

extension OSLogHandler {
	static func currentModule(fileID: String = #fileID) -> String {
		let utf8All = fileID.utf8
		if let slashIndex = utf8All.firstIndex(of: UInt8(ascii: "/")) {
			return String(fileID[..<slashIndex])
		} else {
			return "n/a"
		}
	}
}

#endif
