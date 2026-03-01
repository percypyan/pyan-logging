//
//  CategoryAdderLogHandler.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 02/03/2026.
//

import Foundation

/// A `LogHandler` decorator that injects a logging category into any wrapped handler.
///
/// If the wrapped handler already conforms to ``LogHandlerWithCategory``, the
/// category is forwarded directly. Otherwise, the category is added as a
/// `logger.category` key in the handler's metadata provider.
///
/// You typically don't create this type yourself -- ``LoggerFactory`` uses it
/// automatically when the bootstrap handler doesn't support categories natively.
public struct CategoryAdderLogHandler: LogHandlerWithCategory {
	/// The underlying handler that receives forwarded log messages.
	public private(set) var handler: any LogHandler
	private let originalMetadataProvider: Logger.MetadataProvider?

	private var _category: String?
	public var category: String {
		get {
			if let _category {
				return _category
			} else if let handler = handler as? LogHandlerWithCategory {
				return handler.category
			}
			fatalError("Unexpectedly unable to found category")
		}
		set {
			if var handler = handler as? LogHandlerWithCategory {
				handler.category = newValue
				self.handler = handler
			} else {
				_category = newValue
				onCategoryUpdated()
			}
		}
	}

	public var logLevel: Logging.Logger.Level {
		get { handler.logLevel }
		set { handler.logLevel = newValue }
	}
	public var metadata: Logging.Logger.Metadata {
		get { handler.metadata }
		set { handler.metadata = newValue }
	}
	public var metadataProvider: Logging.Logger.MetadataProvider? {
		get { handler.metadataProvider }
		set { handler.metadataProvider = newValue }
	}

	/// Creates a handler that decorates the given handler with a category.
	///
	/// - Parameters:
	///   - category: The category label to inject.
	///   - handler: The underlying handler to forward log messages to.
	public init(category: String, handler: any LogHandler) {
		if var passedHandler = handler as? LogHandlerWithCategory {
			passedHandler.category = category
			self.handler = passedHandler
			self._category = nil
			self.originalMetadataProvider = nil
		} else {
			self.handler = handler
			self._category = category
			self.originalMetadataProvider = self.handler.metadataProvider
			self.onCategoryUpdated()
		}
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
		handler.log(
			level: level,
			message: message,
			metadata: metadata,
			source: source,
			file: file,
			function: function,
			line: line
		)
	}

	public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
		get { handler[metadataKey: key] }
		set { handler[metadataKey: key] = newValue }
	}
}

extension CategoryAdderLogHandler {
	private mutating func onCategoryUpdated() {
		guard let _category else { return }

		let categoryProvider = Logger.MetadataProvider { ["logger.category": .string(_category)] }
		if let originalMetadataProvider {
			self.handler.metadataProvider = .multiplex([
				categoryProvider,
				originalMetadataProvider // Takes precedence
			])
		} else {
			self.handler.metadataProvider = categoryProvider
		}
	}
}
