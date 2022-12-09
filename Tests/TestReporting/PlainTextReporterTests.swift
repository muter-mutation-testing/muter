import XCTest
import Rainbow
import TestingExtensions

@testable import muterCore

final class PlainTextReporterTests: ReporterTestCase {
    override func setUp() {
        super.setUp()

        // Rainbow is smart, it knows if the stdout is Xcode or the console.
        // We want it to be the console, otherwise the test results are going to differ when running from Xcode vs console
        Rainbow.outputTarget = .console
        Rainbow.enabled = false
    }

    func test_plainTextReporterWithCoverageData() {
        let plainText = PlainTextReporter()
            .report(
                from: .make(
                    mutations: outcomes,
                    coverage: .make(percent: 1)
                )
            )

        XCTAssertEqual(plainText, loadReportOfProjectWithCoverage())
    }

    func test_plainTextReporterWithoutCoverageData() {
        let plainText = PlainTextReporter()
            .report(
                from: .make(
                    mutations: outcomes,
                    coverage: .null
                )
            )

        XCTAssertEqual(plainText, loadReportOfProjectWithoutCoverage())
    }
}

private func loadReportOfProjectWithCoverage() -> String {
    guard let data = FileManager.default.contents(atPath: "\(PlainTextReporterTests().fixturesDirectory)/TestReporting/testReportOfProjectWithCoverage.txt"),
        let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load report for testing")
    }

    return string
}

private func loadReportOfProjectWithoutCoverage() -> String {
    guard let data = FileManager.default.contents(atPath: "\(PlainTextReporterTests().fixturesDirectory)/TestReporting/testReportOfProjectWithoutCoverage.txt"),
        let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load report for testing")
    }

    return string
}
