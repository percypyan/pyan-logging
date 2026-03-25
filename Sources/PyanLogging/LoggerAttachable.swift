//
//  Loggable.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 03/03/2026.
//

/// A type that can contribute structured metadata to a `Logger`.
///
/// Conform model or service types to this protocol so their relevant
/// properties can be attached to log messages via
/// `Logging.Logger/attaching(key:_:)`.
public protocol LoggerAttachable {
	/// The metadata key-value pairs this instance contributes to a logger.
	var logMetadata: Logger.Metadata { get }
}
