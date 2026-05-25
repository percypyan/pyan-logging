//
//  OSLogHandler.swift
//  PyanLogging
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
/// log call: when the merged metadata contains a ``LoggerMetadataKey/category``
/// entry (either `.string` or `.stringConvertible`), it routes to an
/// `os.Logger` configured with that category and removes the key from the
/// formatted metadata. Otherwise, it falls back to the default category
/// supplied at construction.
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
	private let defaultCategory: String
	private let osLoggerProvider: any OSLoggerProvider
	private let metadataStyle: MetadataFormatter.MetadataStyle

	public var logLevel: Logging.Logger.Level = .info
	public var metadata: Logging.Logger.Metadata = [:]
	public var metadataProvider: Logging.Logger.MetadataProvider?

	/// Creates a handler that logs to the unified logging system.
	///
	/// - Parameters:
	///   - label: The subsystem identifier (typically a reverse-DNS string).
	///   - category: The default category, used when a log call's metadata
	///     does not carry a ``LoggerMetadataKey/category`` entry.
	///   - metadataStyle: The style used to format metadata in the log output.
	///   - metadataProvider: An optional provider for dynamic metadata.
	public init(
		label: String,
		category: String,
		metadataStyle: MetadataFormatter.MetadataStyle = .oneLine,
		metadataProvider: Logging.Logger.MetadataProvider? = nil
	) {
		self.init(
			osLoggerProvider: CachingOSLoggerProvider(subsystem: label, seedCategory: category),
			defaultCategory: category,
			metadataStyle: metadataStyle,
			metadataProvider: metadataProvider
		)
	}

	/// Internal designated initializer that accepts a custom ``OSLoggerProvider``.
	///
	/// Used by tests to inject a counting fake; production callers use the
	/// public initializer above, which wires up a ``CachingOSLoggerProvider``.
	init(
		osLoggerProvider: any OSLoggerProvider,
		defaultCategory: String,
		metadataStyle: MetadataFormatter.MetadataStyle = .oneLine,
		metadataProvider: Logging.Logger.MetadataProvider? = nil
	) {
		self.osLoggerProvider = osLoggerProvider
		self.defaultCategory = defaultCategory
		self.metadataStyle = metadataStyle
		self.metadataProvider = metadataProvider
	}

	public func log(event: Logging.LogEvent) {
		// Merge handler, provider, and per-message metadata.
		let merged = Self.prepareMetadata(
			base: self.metadata,
			provider: metadataProvider,
			explicit: event.metadata
		) ?? [:]

		// Resolve the routing category from metadata, falling back to the default.
		let resolution = Self.resolveCategory(from: merged, default: defaultCategory)

		// Strip logger.category from the formatted output only when it drove routing.
		let formattedMetadata = Self.metadata(merged, strippedAfter: resolution)

		let osLogger = osLoggerProvider.osLogger(for: resolution.category)
		let text = formatMessage(event: event, metadata: formattedMetadata)

		// Let os.Logger do the level mapping for us, since methods for all levels are available.
		switch event.level {
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
	/// Resolves the category to route to for a given merged-metadata snapshot.
	///
	/// Accepts both `.string` and `.stringConvertible` variants for the
	/// ``LoggerMetadataKey/category`` entry; any other variant (or absent
	/// key) yields the default category and `usedMetadata == false`.
	static func resolveCategory(
		from metadata: Logging.Logger.Metadata,
		default defaultCategory: String
	) -> (category: String, usedMetadata: Bool) {
		guard let value = metadata[LoggerMetadataKey.category] else {
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

	/// Returns the metadata to format after category resolution.
	///
	/// If the resolution consumed ``LoggerMetadataKey/category`` from the
	/// metadata, that key is removed from the returned dictionary so it
	/// doesn't appear redundantly in the formatted message body. Otherwise,
	/// the metadata is returned unchanged so callers who use the key for
	/// unrelated purposes see it.
	static func metadata(
		_ metadata: Logging.Logger.Metadata,
		strippedAfter resolution: (category: String, usedMetadata: Bool)
	) -> Logging.Logger.Metadata {
		guard resolution.usedMetadata else { return metadata }
		var copy = metadata
		copy.removeValue(forKey: LoggerMetadataKey.category)
		return copy
	}
}

extension OSLogHandler {
	func formatMessage(event: Logging.LogEvent, metadata: Logging.Logger.Metadata) -> String {
		// Other relevant info are generated by OSLog directly:
		// timestamp, bundle, library (that's matching source)

		// Header
		let sourcePrefix = event.source != Self.currentModule(fileID: event.file) ? "[\(event.source)]" : ""
		let header = "[\(event.level.rawValue.uppercased())]\(sourcePrefix)"

		// Error — appended on its own line so the message line stays scannable.
		let errorSuffix = event.error.map { "\n  Error: \($0)" } ?? ""

		// Metadata
		let formatter = MetadataFormatter(style: metadataStyle)
		let metadataString = formatter.string(for: metadata)
		let metadataSuffix = metadataString != nil ? "\n\(metadataString!)" : ""

		return "\(header) \(event.message)\(errorSuffix)\(metadataSuffix)"
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

// MARK: - OSLoggerProvider

/// Supplies an `os.Logger` for a given category.
///
/// Production use wires up ``CachingOSLoggerProvider``; tests can substitute
/// a counting fake to assert on cache behaviour.
protocol OSLoggerProvider: Sendable {
	func osLogger(for category: String) -> os.Logger
}

/// Reference-typed memoization of `os.Logger` instances keyed by category.
///
/// `Mutex` is `~Copyable` and so cannot live directly in a `Copyable`
/// struct; wrapping it in a final class keeps `OSLogHandler` a value type
/// while still allowing the cache to be shared between copies. The cache
/// only stores derived state, so sharing is benign.
final class CachingOSLoggerProvider: OSLoggerProvider, Sendable {
	private let subsystem: String
	private let storage: Mutex<[String: os.Logger]>

	init(subsystem: String, seedCategory: String) {
		self.subsystem = subsystem
		self.storage = Mutex([
			seedCategory: os.Logger(subsystem: subsystem, category: seedCategory)
		])
	}

	func osLogger(for category: String) -> os.Logger {
		storage.withLock { cache in
			if let cached = cache[category] {
				return cached
			}
			let made = os.Logger(subsystem: subsystem, category: category)
			cache[category] = made
			return made
		}
	}

	#if DEBUG
	/// The set of categories currently cached. Test-only.
	var cachedCategoriesForTesting: Set<String> {
		storage.withLock { Set($0.keys) }
	}
	#endif
}

#if DEBUG
extension OSLogHandler {
	/// The set of categories whose `os.Logger` instances have been cached.
	/// Only meaningful when the handler is using a ``CachingOSLoggerProvider``
	/// (which is the case when constructed via the public initializer).
	/// Test-only.
	var cachedCategoriesForTesting: Set<String> {
		(osLoggerProvider as? CachingOSLoggerProvider)?.cachedCategoriesForTesting ?? []
	}
}
#endif

#endif
