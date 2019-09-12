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
                .withoutScheme()
        )
    }

    var fixturesDirectory: String { return "\(rootTestDirectory)/fixtures" }
    var configurationPath: String { return "\(fixturesDirectory)/muter.conf.json" }
    var mutationExamplesDirectory: String { return "\(fixturesDirectory)/MutationExamples" }

    var exampleMutationTestResults: [MutationTestOutcome] {
        return [
            MutationTestOutcome(testSuiteOutcome: .failed, mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/file1.swift", position: .firstPosition), operatorDescription: "from == to !="),
            MutationTestOutcome(testSuiteOutcome: .failed, mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/file1.swift", position: .firstPosition), operatorDescription: "from == to !="),
            MutationTestOutcome(testSuiteOutcome: .passed, mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/file1.swift", position: .firstPosition), operatorDescription: "from == to !="),
            
            MutationTestOutcome(testSuiteOutcome: .failed, mutationPoint: MutationPoint(mutationOperatorId: .removeSideEffects, filePath: "/tmp/file2.swift", position: .firstPosition), operatorDescription: "from == to !="),
            MutationTestOutcome(testSuiteOutcome: .failed, mutationPoint: MutationPoint(mutationOperatorId: .removeSideEffects, filePath: "/tmp/file2.swift", position: .firstPosition), operatorDescription: "from == to !="),
            
            MutationTestOutcome(testSuiteOutcome: .failed, mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/file3.swift", position: .firstPosition), operatorDescription: "from == to !="),
            MutationTestOutcome(testSuiteOutcome: .passed, mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/file3.swift", position: .firstPosition), operatorDescription: "from == to !="),
            MutationTestOutcome(testSuiteOutcome: .passed, mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/file3.swift", position: .firstPosition), operatorDescription: "from == to !="),
            
            MutationTestOutcome(testSuiteOutcome: .passed, mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/file 4.swift", position: .firstPosition), operatorDescription: "from == to !=") // this file name intentionally has a space in it
        ]
    }
}
