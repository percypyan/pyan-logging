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
	/// `logger.category` is a reserved key. Handlers that route on category
	/// (such as ``OSLogHandler``) consume it natively. Other handlers receive
	/// it as ordinary metadata.
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
