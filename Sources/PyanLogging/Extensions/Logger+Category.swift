//
//  Logger+Category.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 04/03/2026.
//

public extension Logger {
	/// Returns a copy of this logger with the given category applied.
	///
	/// If the logger's handler conforms to ``LogHandlerWithCategory``, the
	/// category is set directly. Otherwise the handler is wrapped in a
	/// ``CategoryAdderLogHandler`` that injects it as metadata.
	///
	/// This is useful when you already have a `Logger` instance (for example
	/// one created outside of ``LoggerFactory``) and want to assign a category
	/// to it.
	///
	/// ```swift
	/// var logger = Logger(label: "com.example.myapp")
	/// logger = logger.categorized(AppLogCategory.network)
	/// ```
	///
	/// - Parameter category: The category to associate with the logger.
	/// - Returns: A new `Logger` whose handler includes the category.
	func categorized(_ category: any LogCategory) -> Self {
		var newLogger: Logger = self

		if var handler = newLogger.handler as? LogHandlerWithCategory {
			handler.category = category.label
			newLogger.handler = handler
		} else {
			newLogger.handler = CategoryAdderLogHandler(
				category: category.label,
				handler: newLogger.handler
			)
		}

		return newLogger
	}
}
