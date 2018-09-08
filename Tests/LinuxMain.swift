import XCTest

import muterTests

var tests = [XCTestCaseEntry]()
tests += muterTests.allTests()
XCTMain(tests)