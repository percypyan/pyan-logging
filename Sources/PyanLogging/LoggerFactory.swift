//
//  PyanLogging.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 01/03/2026.
//
//

import Foundation

/// Creates pre-configured `Logger` instances scoped to a specific ``LogCategory``.
///
/// `LoggerFactory` is the main entry point for obtaining loggers. It wraps
/// swift-log's `Logger` and ensures every logger it produces carries the
/// appropriate category metadata.
///
/// If the bootstrap handler already conforms to ``LogHandlerWithCategory``,
/// the category is set directly. Otherwise the handler is wrapped in a
/// ``CategoryAdderLogHandler`` that injects the category as metadata.
public struct LoggerFactory<Category: LogCategory>: Sendable {
	private let label: String
	private let handlerFactory: (@Sendable (String) -> any LogHandler)?
	private let handlerFactoryWithMetadata: (@Sendable (String, Logger.MetadataProvider?) -> any LogHandler)?
	private let metadataProvider: Logger.MetadataProvider?

	/// Creates a factory that produces loggers with the given subsystem label.
	///
	/// - Parameter label: The subsystem identifier passed to swift-log
	///   (typically a reverse-DNS string such as `"com.example.myapp"`).
	public init(label: String) {
		self.label = label
		self.handlerFactory = nil
		self.handlerFactoryWithMetadata = nil
		self.metadataProvider = nil
	}

	/// Creates a factory that produces loggers using a custom handler factory.
	///
	/// Use this initializer when you want full control over the `LogHandler`
	/// that backs each logger.
	///
	/// - Parameters:
	///   - label: The subsystem identifier passed to swift-log
	///     (typically a reverse-DNS string such as `"com.example.myapp"`).
	///   - factory: A closure that creates a `LogHandler` for the given label.
	public init(label: String, factory: @Sendable @escaping (String) -> any LogHandler) {
		self.label = label
		self.handlerFactory = factory
		self.handlerFactoryWithMetadata = nil
		self.metadataProvider = nil
	}

	/// Creates a factory that produces loggers using a custom handler factory
	/// with metadata provider support.
	///
	/// Use this initializer when you need a custom handler that also accepts a
	/// `Logger.MetadataProvider` for dynamic metadata injection.
	///
	/// - Parameters:
	///   - label: The subsystem identifier passed to swift-log
	///     (typically a reverse-DNS string such as `"com.example.myapp"`).
	///   - factory: A closure that creates a `LogHandler` for the given label
	///     and optional metadata provider.
	public init(label: String, factory: @Sendable @escaping (String, Logger.MetadataProvider?) -> any LogHandler) {
		self.label = label
		self.handlerFactory = nil
		self.handlerFactoryWithMetadata = factory
		self.metadataProvider = nil
	}

	/// Creates a factory that produces loggers with a metadata provider.
	///
	/// The metadata provider is forwarded to the bootstrapped `Logger`,
	/// allowing dynamic metadata to be included in every log message.
	/// This pairs well with ``MetadataContainer/provider``.
	///
	/// - Parameters:
	///   - label: The subsystem identifier passed to swift-log
	///     (typically a reverse-DNS string such as `"com.example.myapp"`).
	///   - metadataProvider: The metadata provider to attach to each logger.
	public init(label: String, metadataProvider: Logger.MetadataProvider) {
		self.label = label
		self.handlerFactory = nil
		self.handlerFactoryWithMetadata = nil
		self.metadataProvider = metadataProvider
	}

	/// Returns a new `Logger` configured for the given category.
	///
	/// - Parameter category: The category to associate with the logger.
	/// - Returns: A `Logger` whose handler includes the category information.
	public func logger(for category: Category) -> Logger {
		return makeLogger().categorized(category)
	}

	private func makeLogger() -> Logger {
		if let factory = handlerFactory {
			return Logger(label: label, factory: factory)
		} else if let factory = handlerFactoryWithMetadata {
			return Logger(label: label, factory: factory)
		} else if let metadataProvider {
			return Logger(label: label, metadataProvider: metadataProvider)
		}

		return Logger(label: label)
	}
}
