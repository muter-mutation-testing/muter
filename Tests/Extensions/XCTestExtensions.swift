import XCTest
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
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }

    var fixturesDirectory: String { return "\(rootTestDirectory)/fixtures" }
    var configurationPath: String { return "\(fixturesDirectory)/muter.conf.json" }
    var mutationExamplesDirectory: String { return "\(fixturesDirectory)/MutationExamples" }

    var exampleMutationTestResults: [MutationTestOutcome] {
        return [
            MutationTestOutcome(testSuiteOutcome: .failed, appliedMutation: .negateConditionals, filePath: "file1.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteOutcome: .failed, appliedMutation: .negateConditionals, filePath: "file1.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteOutcome: .passed, appliedMutation: .negateConditionals, filePath: "file1.swift", position: .firstPosition),

            MutationTestOutcome(testSuiteOutcome: .failed, appliedMutation: .removeSideEffects, filePath: "file2.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteOutcome: .failed, appliedMutation: .removeSideEffects, filePath: "file2.swift", position: .firstPosition),

            MutationTestOutcome(testSuiteOutcome: .failed, appliedMutation: .negateConditionals, filePath: "file3.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteOutcome: .passed, appliedMutation: .negateConditionals, filePath: "file3.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteOutcome: .passed, appliedMutation: .negateConditionals, filePath: "file3.swift", position: .firstPosition),

            MutationTestOutcome(testSuiteOutcome: .passed, appliedMutation: .negateConditionals, filePath: "file 4.swift", position: .firstPosition) // this file name intentionally has a space in it
        ]
    }
}
