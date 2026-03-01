//
//  LogWithCategoryHandler.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 02/03/2026.
//

import Foundation

/// A `LogHandler` that supports a mutable logging category.
///
/// Conform your custom log handlers to this protocol so that
/// ``LoggerFactory`` can set the category directly instead of
/// wrapping the handler in a ``CategoryAdderLogHandler``.
public protocol LogHandlerWithCategory: LogHandler {
	/// The current logging category label.
	var category: String { get set }
}
