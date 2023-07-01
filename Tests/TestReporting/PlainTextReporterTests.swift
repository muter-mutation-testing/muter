@testable import muterCore
import Rainbow
import TestingExtensions
import XCTest

final class PlainTextReporterTests: ReporterTestCase {
    override func setUp() {
        super.setUp()

        // Rainbow is smart, it knows if the stdout is Xcode or the console.
        // We want it to be the console, otherwise the test results are going to differ when running from Xcode vs
        // console
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

        AssertSnapshot(plainText)
    }

    func test_plainTextReporterWithoutCoverageData() {
        let plainText = PlainTextReporter()
            .report(
                from: .make(
                    mutations: outcomes,
                    coverage: .null
                )
            )

        AssertSnapshot(plainText)
    }
}
