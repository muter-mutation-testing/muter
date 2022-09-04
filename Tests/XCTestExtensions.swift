import XCTest
import TestingExtensions

@testable import muterCore

public extension XCTestCase {
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }

    var rootTestDirectory: String {
        return String(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }

    var fixturesDirectory: String { return "\(rootTestDirectory)/fixtures" }
    var configurationPath: String { return "\(fixturesDirectory)/\(MuterConfiguration.fileNameWithExtension)" }
    var mutationExamplesDirectory: String { return "\(fixturesDirectory)/MutationExamples" }

    var exampleMutationTestResults: [MutationTestOutcome.Mutation] {
        return [
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .removeSideEffects,
                    filePath: "/tmp/file2.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .removeSideEffects,
                    filePath: "/tmp/file2.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file 4.swift", // this file name intentionally has a space in it
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
        ]
    }
}
