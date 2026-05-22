//
//  LoggerMetadataKey.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 22/05/2026.
//

/// Conventional metadata keys carried by PyanLogging loggers.
///
/// These keys are written by the package and may be consumed by handlers
/// that opt in. Handlers are free to inspect them for their own routing,
/// display, or tagging logic -- or to ignore them entirely.
public enum LoggerMetadataKey {
	/// The category label attached by ``Logger/categorized(_:)`` and
	/// ``LoggerFactory/logger(for:)``. ``OSLogHandler`` routes its
	/// `os.Logger` calls on this value.
	public static let category = "logger.category"
}
