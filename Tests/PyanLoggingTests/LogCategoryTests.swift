//
//  LogCategoryTests.swift
//  PyanLogging
//
//  Created by Claude on 04/03/2026.
//

import Testing
@testable import PyanLogging

@Suite("LogCategory")
struct LogCategoryTests {

	@Test("String-backed enum default label is rawValue.capitalized")
	func defaultLabel() {
		#expect(TestLogCategory.network.label == "Network")
		#expect(TestLogCategory.database.label == "Database")
		#expect(TestLogCategory.ui.label == "Ui")
	}
}
