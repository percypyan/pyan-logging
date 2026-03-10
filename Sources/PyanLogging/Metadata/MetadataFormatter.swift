//
//  MetadataFormatter.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 09/03/2026.
//

/// Converts `Logger.Metadata` into a human-readable string using a configurable ``MetadataStyle``.
///
/// Each style produces a different layout (single line, one-pair-per-line, or
/// dictionary literal). Additional properties control indentation, whether
/// the dictionary style is collapsed onto one line, and whether empty metadata
/// is suppressed entirely.
///
/// ```swift
/// let formatter = MetadataFormatter(style: .oneLine)
/// if let text = formatter.string(for: metadata) {
///     print(text) // > requestId = abc-123 | userId = 42
/// }
/// ```
public struct MetadataFormatter: Sendable {
	/// The layout style used to render metadata.
	public var style: MetadataStyle = .oneLine

	/// When `true` (the default), ``string(for:)`` returns `nil` for empty metadata.
	public var isEmptyMetadataHidden = true

	/// When `true`, the ``MetadataStyle/dictionary`` style collapses its output
	/// onto a single line instead of using newlines between entries.
	public var isDictionaryOneLined = false

	/// The string used for each indentation level in ``MetadataStyle/dictionary``
	/// output. Ignored when ``isDictionaryOneLined`` is `true`. Defaults to `"\t"`.
	public var indentString = "\t"

	/// Creates a formatter with the given style.
	///
	/// - Parameter style: The metadata layout style to use.
	public init(style: MetadataStyle) {
		self.style = style
	}

	private var _indentString: String {
		return isDictionaryOneLined ? "" : indentString
	}

	/// Returns a formatted string representation of the given metadata, or `nil`
	/// if the metadata is empty and ``isEmptyMetadataHidden`` is `true`, or if
	/// the style is ``MetadataStyle/hidden``.
	///
	/// - Parameter metadata: The logger metadata to format.
	/// - Returns: A formatted string, or `nil` when output should be suppressed.
	public func string(for metadata: Logging.Logger.Metadata) -> String? {
		guard !(metadata.isEmpty && isEmptyMetadataHidden) else {
			return nil
		}

		switch style {
		case .oneLine:
			let metadataString = metadata
				.flattening()
				.map { "\($0.0) = \($0.1)" }
				.sorted()
				.joined(separator: " | ")
			return "> \(metadataString)"
		case .multiline:
			let metadataString = metadata
				.flattening()
				.map { "\($0.0) = \($0.1)" }
				.sorted()
				.joined(separator: "\n> ")
			return "> \(metadataString)"
		case .dictionary:
			var lines: [String] = []
			formatDictionaryMetadataValue(
				key: nil,
				value: .dictionary(metadata),
				indentation: "",
				lines: &lines
			)
			return lines.joined(separator: isDictionaryOneLined ? "" : "\n")
		case .hidden: return nil
		}
	}

	private func formatDictionaryMetadataValue(
		key: String?,
		value: Logging.Logger.Metadata.Value,
		indentation: String,
		lines: inout [String],
		skipTerminator: Bool = true
	) {
		let keyPrefix = key != nil ? "\"\(key!)\": " : ""
		let terminator = skipTerminator ? "" : ","
		switch value {
		case .string(let string):
			lines.append("\(indentation)\(keyPrefix)\"\(string)\"\(terminator)")
		case .stringConvertible(let string):
			lines.append("\(indentation)\(keyPrefix)\"\(string)\"\(terminator)")
		case .array(let array):
			guard !array.isEmpty else {
				lines.append("\(indentation)\(keyPrefix)[]\(terminator)")
				return
			}
			lines.append("\(indentation)\(keyPrefix)[")
			for (index, item) in array.enumerated() {
				formatDictionaryMetadataValue(
					key: nil,
					value: item,
					indentation: "\(indentation)\(_indentString)",
					lines: &lines,
					skipTerminator: index == array.count - 1
				)
			}
			lines.append("\(indentation)]\(terminator)")
		case .dictionary(let dict):
			guard !dict.isEmpty else {
				lines.append("\(indentation)\(keyPrefix)[:]\(terminator)")
				return
			}
			lines.append("\(indentation)\(keyPrefix)[")
			for (index, (key, value)) in dict.enumerated() {
				formatDictionaryMetadataValue(
					key: key,
					value: value,
					indentation: "\(indentation)\(_indentString)",
					lines: &lines,
					skipTerminator: index == dict.count - 1
				)
			}
			lines.append("\(indentation)]\(terminator)")
		}
	}
}

public extension MetadataFormatter {
	/// Controls how metadata key-value pairs are formatted in log output.
	///
	/// The metadata style determines the visual layout of metadata appended
	/// after the log message. Choose a style based on readability needs:
	///
	/// ```
	/// // .oneLine (default)
	/// [INFO] Request completed
	/// > requestId = abc-123 | userId = 42
	///
	/// // .multiline
	/// [INFO] Request completed
	/// > requestId = abc-123
	/// > userId = 42
	///
	/// // .dictionary
	/// [INFO] Request completed
	/// [
	///     "requestId": "abc-123",
	///     "userId": "42"
	/// ]
	///
	/// // .hidden
	/// [INFO] Request completed
	/// ```
	enum MetadataStyle: Sendable {
		/// All metadata on a single line, separated by ` | `.
		case oneLine
		/// Each metadata pair on its own line, prefixed with `> `.
		case multiline
		/// The metadata dictionary's printed on multiple lines.
		case dictionary
		/// Suppresses metadata output entirely.
		case hidden
	}
}
