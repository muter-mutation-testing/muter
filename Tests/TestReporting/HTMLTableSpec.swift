@testable import muterCore

import SwiftSyntax

import Foundation
import TestingExtensions
import Quick
import Nimble

class HTMLTableSpec: QuickSpec {
    override func spec() {
        let sut = HTMLReporter()
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

        describe("HTMLTable") {
            it("should render an HTML file") {
                let html = sut.report(from: outcomes)

                expect(html).to(
                    equalWithDiff(
                        """
                        """
                    )
                )
            }
        }
    }
}
