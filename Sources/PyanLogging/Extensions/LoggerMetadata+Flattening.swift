//
//  LoggerMetadata+Flattening.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

import Foundation

/// Defines how nested metadata keys are represented when flattened into a single level.
///
/// For example, with ``dot`` representation a nested key `["user"]["name"]`
/// becomes `"user.name"`, while ``brackets`` produces `"user[name]"`.
public struct NestedPathRepresentation: Sendable {
	let opening: String
	let closing: String

	private init(_ opening: String, _ closing: String = "") {
		self.opening = opening
		self.closing = closing
	}

	/// Dot notation: `parent.child`
	public static let dot: NestedPathRepresentation = .init(".")
	/// Bracket notation: `parent[child]`
	public static let brackets: NestedPathRepresentation = .init("[", "]")
	/// Chevron notation: `parent<child>`
	public static let chevrons: NestedPathRepresentation = .init("<", ">")
	/// Parenthesis notation: `parent(child)`
	public static let parentheses: NestedPathRepresentation = .init("(", ")")
	/// Curly brace notation: `parent{child}`
	public static let curlyBraces: NestedPathRepresentation = .init("{", "}")

	/// Creates a representation using the given string as a separator between path components.
	public static func custom(_ separator: String) -> NestedPathRepresentation {
		return .init(separator)
	}

	/// Creates a representation that wraps child keys between an opening and closing string.
	public static func customWrapping(opening: String, closing: String) -> NestedPathRepresentation {
		return .init(opening, closing)
	}
}

public extension Logger.Metadata {
	/// Returns a new metadata dictionary with all nested dictionaries and arrays
	/// flattened into single-level key-value pairs.
	///
	/// - Parameters:
	///   - nestedDictionaryPathRepresentation: How nested dictionary keys are
	///     joined (defaults to ``NestedPathRepresentation/dot``).
	///   - nestedArrayPathRepresentation: How array indices are represented
	///     (defaults to ``NestedPathRepresentation/brackets``).
	/// - Returns: A flat metadata dictionary.
	func flattening(
		nestedDictionaryPathRepresentation: NestedPathRepresentation = .dot,
		nestedArrayPathRepresentation: NestedPathRepresentation = .brackets
	) -> Logger.Metadata {
		let flattener = MetadataFlattener(
			nestedDictionaryPathRepresentation: nestedDictionaryPathRepresentation,
			nestedArrayPathRepresentation: nestedArrayPathRepresentation
		)
		return flattener
			.flatteningMetadata(self)
	}
}

fileprivate struct MetadataFlattener {
	let nestedDictionaryPathRepresentation: NestedPathRepresentation
	let nestedArrayPathRepresentation: NestedPathRepresentation

	func flatteningMetadata(
		_ metadata: Logging.Logger.Metadata,
		keyPrefix: String? = nil
	) -> Logging.Logger.Metadata {
		var flattened: Logging.Logger.Metadata = [:]

		for (key, value) in metadata {
			flattened.merge(
				metadataFrom(key: newKey(prefix: keyPrefix, key: key), value: value),
				uniquingKeysWith: { $1 }
			)
		}

		return flattened
	}

	private func metadataFrom(
		key: String,
		value: Logging.Logger.MetadataValue
	) -> Logging.Logger.Metadata {
		switch value {
		case .dictionary(let dict):
			return flatteningMetadata(dict, keyPrefix: key)
		case .array(let array):
			var flattened: Logging.Logger.Metadata = [:]
			for (index, item) in array.enumerated() {
				flattened.merge(
					metadataFrom(key: newKey(prefix: key, index: index), value: item),
					uniquingKeysWith: { $1 }
				)
			}
			return flattened
		default:
			return [key: value]
		}
	}

	private func newKey(prefix: String?, key: String) -> String {
		guard let prefix else { return key }

		let opening = nestedDictionaryPathRepresentation.opening
		let closing = nestedDictionaryPathRepresentation.closing
		return "\(prefix)\(opening)\(key)\(closing)"
	}

	private func newKey(prefix: String, index: Int) -> String {
		let opening = nestedArrayPathRepresentation.opening
		let closing = nestedArrayPathRepresentation.closing
		return "\(prefix)\(opening)\(index)\(closing)"
	}
}
