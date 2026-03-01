//
//  LogCategory.swift
//  PyanLogging
//
//  Created by Perceval Archimbaud on 02/03/2026.
//

import Foundation

/// A type that represents a logging category used to classify log messages.
///
/// Any `Sendable` and `Hashable` type can conform to this protocol by
/// providing a ``label``. When the conforming type is a `String`-backed
/// `RawRepresentable` (e.g. an enum), a default ``label`` is automatically
/// derived by capitalizing the raw value.
public protocol LogCategory: Sendable, Hashable {
	/// A human-readable label for this category, used in log output.
	var label: String { get }
}

public extension LogCategory where Self: RawRepresentable, RawValue == String {
	var label: String { rawValue.capitalized }
}
