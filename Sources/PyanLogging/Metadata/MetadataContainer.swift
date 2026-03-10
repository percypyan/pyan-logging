//
//  MetadataContainer.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 02/03/2026.
//

import Synchronization

/// A type that defines keys for use with ``MetadataContainer``.
///
/// Conform a `String`-backed enum to this protocol to define a closed set of
/// metadata keys. An optional ``prefix`` prepends a namespace to every key,
/// and ``nestedMetadataSeparator`` enables automatic nesting within the
/// container's metadata dictionary.
public protocol MetadataKey: RawRepresentable<String>, Sendable {
	/// An optional namespace prefix prepended to the raw value (joined with a dot).
	var prefix: String? { get }
	/// When set, the raw value is split on this separator to create nested metadata dictionaries.
	var nestedMetadataSeparator: String? { get }
	/// The fully-qualified key, combining ``prefix`` and the raw value.
	var key: String { get }
}

public extension MetadataKey {
	var prefix: String? { nil }
	var nestedMetadataSeparator: String? { nil }
	var key: String { `prefix` != nil ? "\(`prefix`!).\(rawValue)" : "\(rawValue)" }
}

/// A thread-safe container for managing `Logger.Metadata` with typed keys.
///
/// `MetadataContainer` is backed by a `Mutex` and can be safely updated from
/// any concurrency context. It supports flat and nested metadata structures
/// and can produce a ``Logging/Logger/MetadataProvider`` for integration with
/// swift-log handlers.
public final class MetadataContainer<Key: MetadataKey>: Sendable {
	private let container = Mutex(Logger.Metadata())

	/// A snapshot of the current metadata.
	public var metadata: Logger.Metadata {
		container.withLock { $0 }
	}

	/// Updates the value for the given key.
	///
	/// If the key defines a ``MetadataKey/nestedMetadataSeparator``, the raw
	/// value is split into path components and the value is stored in a nested
	/// dictionary structure. Pass `nil` to remove the key.
	///
	/// - Parameters:
	///   - key: The metadata key to update.
	///   - value: The new value, or `nil` to remove it.
	/// - Returns: `self`, to allow chaining.
	@discardableResult
	public func update(_ key: Key, value: Logger.Metadata.Value?) -> Self {
		guard let separator = key.nestedMetadataSeparator else {
			container.withLock { metadata in
				if let value {
					metadata[key.key] = value
				} else {
					metadata.removeValue(forKey: key.key)
				}
			}
			return self
		}

		let path = key.rawValue.split(separator: separator).map(String.init)
		container.withLock { metadata in
			metadata = Self.updateNested(value: value, path: path, in: metadata)
		}
		return self
	}

	/// A `MetadataProvider` that returns the container's current metadata.
	///
	/// Attach this to a `LogHandler` so that every log message automatically
	/// includes the container's metadata.
	public var provider: Logger.MetadataProvider {
		Logger.MetadataProvider { [self] in
			self.metadata
		}
	}

	/// Creates a container with optional initial metadata.
	///
	/// - Parameter metadata: The initial metadata dictionary (empty by default).
	public init(_ metadata: Logger.Metadata = [:]) {
		container.withLock { $0 = metadata }
	}

	private static func updateNested(
		value: Logger.MetadataValue?,
		path: [String],
		in metadata: Logger.Metadata
	) -> Logger.Metadata {
		guard let key = path.first else { return metadata }

		var newMetadata = metadata

		guard path.count > 1 else {
			if let value {
				newMetadata[key] = value
			} else {
				newMetadata.removeValue(forKey: key)
			}
			return newMetadata
		}

		let newDict: Logger.Metadata

		if case .dictionary(let dict) = metadata[key] {
			newDict = updateNested(value: value, path: Array(path.dropFirst()), in: dict)
		} else if metadata[key] == nil {
			newDict = updateNested(value: value, path: Array(path.dropFirst()), in: [:])
		} else {
			// Unexpected type already existing, do not update
			return metadata
		}

		newMetadata[key] = .dictionary(newDict)
		return newMetadata
	}
}

// MARK: - Convenience

public extension MetadataContainer {
	@discardableResult
	func update(_ key: Key, value: String?) -> Self {
		return update(key, value: value != nil ? .string(value!) : nil)
	}

	@discardableResult
	func update(_ key: Key, value: Logger.Metadata?) -> Self {
		return update(key, value: value != nil ? .dictionary(value!) : nil)
	}

	@discardableResult
	func update(_ key: Key, value: [Logger.MetadataValue]?) -> Self {
		return update(key, value: value != nil ? .array(value!) : nil)
	}

	@discardableResult
	func update(_ key: Key, value: (any CustomStringConvertible & Sendable)?) -> Self {
		return update(key, value: value != nil ? .stringConvertible(value!) : nil)
	}
}
