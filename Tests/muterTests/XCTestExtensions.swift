import XCTest
@testable import muterCore

extension XCTestCase {
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
    
    var testDirectory: String {
        return String(
            URL(string: #file)!
                .deletingLastPathComponent()
                .absoluteString
                .dropLast()
        )
    }
    
    var fixturesDirectory: String { return "\(testDirectory)/fixtures" }
    var configurationPath: String { return "\(fixturesDirectory)/muter.conf.json" }
	
	var exampleMutationTestResults: [MutationTestOutcome] {
		return [
			MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeMutation", filePath: "file1.swift"),
			MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeMutation", filePath: "file1.swift"),
			MutationTestOutcome(testSuiteResult: .passed, appliedMutation: "SomeMutation", filePath: "file1.swift"),
			
			MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeOtherMutation", filePath: "file2.swift"),
			MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeOtherMutation", filePath: "file2.swift"),
			
			MutationTestOutcome(testSuiteResult: .failed, appliedMutation: "SomeMutation", filePath: "file3.swift"),
			MutationTestOutcome(testSuiteResult: .passed, appliedMutation: "SomeMutation", filePath: "file3.swift"),
			MutationTestOutcome(testSuiteResult: .passed, appliedMutation: "SomeMutation", filePath: "file3.swift"),
			
			MutationTestOutcome(testSuiteResult: .passed, appliedMutation: "SomeMutation", filePath: "file4.swift")
		]
	}
}
