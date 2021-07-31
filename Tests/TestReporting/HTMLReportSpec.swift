@testable import muterCore

import SwiftSyntax

import Foundation
import TestingExtensions
import Quick
import Nimble

class HTMLReportSpec: QuickSpec {
    override func spec() {
        let dateStub = {
            DateComponents(
                calendar: .init(identifier: .gregorian),
                year: 2021,
                month: 1,
                day: 20,
                hour: 2,
                minute: 42
            ).date!
        }()
        
        let sut = HTMLReporter(now: { dateStub })
        let mutations: [MutationTestOutcome.Mutation] = (0...50).map {
            MutationTestOutcome.Mutation.make(
                testSuiteOutcome: nextMutationTestOutcome($0),
                point: .make(
                    mutationOperatorId: nextMutationOperator($0),
                    filePath: "/root/file\($0).swift",
                    position: .init(integerLiteral: $0)
                ),
                snapshot: .make(before: "before", after: "after"),
                originalProjectDirectoryUrl: URL(fileURLWithPath: "/root/")
            )
        }

        describe("HTMLReport") {
            context("when outcome have coverage data") {
                it("should output HTML report with coverage") {
                    let outcome = MutationTestOutcome.make(
                        mutations: mutations,
                        coverage: .make(percent: 78)
                    )
                    let actual = sut.report(from: outcome)
                    let expected = loadReportOfProjectWithCoverage()
                    
                    expect(actual).to(equalWithDiff(expected))
                }
            }
            
            context("when outcome doesn't have coverage data") {
                it("should output HTML report without coverage") {
                    let outcome = MutationTestOutcome.make(
                        mutations: mutations,
                        coverage: .null
                    )
                    let actual = sut.report(from: outcome)
                    let expected = loadReportOfProjectWithoutCoverage()
                    
                    expect(actual).to(equalWithDiff(expected))
                }
            }
        }
    }
}

private func loadReportOfProjectWithoutCoverage() -> String {
    guard let data = FileManager.default.contents(atPath: "\(HTMLReportSpec().fixturesDirectory)/TestReporting/testReportOfProjectWithoutCoverage.html"),
          let string = String(data: data, encoding: .utf8) else {
        fatalError("Unable to load report for testing")
    }
    
    return string
}

private func loadReportOfProjectWithCoverage() -> String {
    guard let data = FileManager.default.contents(atPath: "\(HTMLReportSpec().fixturesDirectory)/TestReporting/testReportOfProjectWithCoverage.html"),
          let string = String(data: data, encoding: .utf8) else {
        fatalError("Unable to load report for testing")
    }
    
    return string
}
