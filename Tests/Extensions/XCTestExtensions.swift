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
            MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeMutation", filePath: "file1.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeMutation", filePath: "file1.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteResult: .passed, appliedMutation: "SomeMutation", filePath: "file1.swift", position: .firstPosition),

            MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeOtherMutation", filePath: "file2.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeOtherMutation", filePath: "file2.swift", position: .firstPosition),

            MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeMutation", filePath: "file3.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteResult: .passed, appliedMutation: "SomeMutation", filePath: "file3.swift", position: .firstPosition),
            MutationTestOutcome(testSuiteResult: .passed, appliedMutation: "SomeMutation", filePath: "file3.swift", position: .firstPosition),

            MutationTestOutcome(testSuiteResult: .passed, appliedMutation: "SomeMutation", filePath: "file 4.swift", position: .firstPosition)
        ]
    }
}
