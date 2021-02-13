@testable import muterCore

import SwiftSyntax

import Foundation
import TestingExtensions
import Quick
import Nimble

class HTMLReportSpec: QuickSpec {
    override func spec() {
        let now = {
            DateComponents(
                calendar: .init(identifier: .gregorian),
                year: 2021,
                month: 1,
                day: 20,
                hour: 2,
                minute: 42
            ).date!
        }()

        let sut = HTMLReporter(now: { now })
        let outcomes = (0...50).map {
            MutationTestOutcome.make(
                testSuiteOutcome: nextMutationTestOutcome($0),
                mutationPoint: .make(
                    mutationOperatorId: nextMutationOperator($0),
                    filePath: "/root/file\($0).swift",
                    position: .init(integerLiteral: $0)
                ),
                mutationSnapshot: .make(before: "before", after: "after"),
                originalProjectDirectoryUrl: URL(fileURLWithPath: "/root/")
            )
        }

        describe("HTMLReport") {
            it("should output an HTML file") {
                let actual = sut.report(from: outcomes)
                let expected = loadReport()
                
                expect(actual).to(equalWithDiff(expected))
            }
        }
    }
}

private func loadReport() -> String {
    guard let data = FileManager.default.contents(atPath: "\(HTMLReportSpec().fixturesDirectory)/TestReporting/testReport.html"),
        let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load reportfor testing")
    }

    return string
}
