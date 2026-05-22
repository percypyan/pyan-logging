//
//  Logger+Category.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 04/03/2026.
//

public extension Logger {
	/// Returns a copy of this logger with the given category attached as
	/// `logger.category` metadata.
	///
	/// `logger.category` is a conventional key carried in the logger's
	/// metadata. Each handler decides how to use it: ``OSLogHandler`` (shipped
	/// with this package) routes `os.Logger` calls on it, but any handler is
	/// free to inspect the key for its own routing, display, or tagging
	/// logic -- or to ignore it entirely.
	///
	/// ```swift
	/// var logger = Logger(label: "com.example.myapp")
	/// logger = logger.categorized(AppLogCategory.network)
	/// ```
	///
	/// - Parameter category: The category to associate with the logger.
	/// - Returns: A new `Logger` carrying the category in its metadata.
	func categorized(_ category: any LogCategory) -> Self {
		var copy = self
		copy[metadataKey: "logger.category"] = .string(category.label)
		return copy
	}
}
