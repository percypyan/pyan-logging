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

	@Test("String-backed enum default label upper-cases the first character")
	func defaultLabel() {
		#expect(TestLogCategory.network.label == "Network")
		#expect(TestLogCategory.database.label == "Database")
		#expect(TestLogCategory.ui.label == "Ui")
	}

	@Test("Default label preserves the internal casing of camelCase raw values")
	func preservesCamelCase() {
		enum CamelCategory: String, LogCategory {
			case staticGolfMap
			case httpRequestParser
		}

		#expect(CamelCategory.staticGolfMap.label == "StaticGolfMap")
		#expect(CamelCategory.httpRequestParser.label == "HttpRequestParser")
	}

	@Test("Default label handles an empty raw value without crashing")
	func emptyRawValue() {
		enum EmptyCategory: String, LogCategory {
			case blank = ""
		}

		#expect(EmptyCategory.blank.label == "")
	}
}
