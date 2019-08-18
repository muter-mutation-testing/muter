@testable import muterCore

class FileReportProvider {

    static var expectedFileReport1: MuterTestReport.FileReport {
        return .init(fileName: "a module.swift", path: "/tmp/a module.swift", mutationScore: 100, appliedOperators: [
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/a module.swift", position: .firstPosition),
                                                    testSuiteOutcome: .failed)
        ])
    }

    static var expectedFileReport2: MuterTestReport.FileReport {
        return .init(fileName: "file 4.swift", path: "/tmp/file 4.swift", mutationScore: 0, appliedOperators: [
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/file 4.swift", position: .firstPosition),
                                                    testSuiteOutcome: .passed)
        ])
    }

    static var expectedFileReport3: MuterTestReport.FileReport {
        return .init(fileName: "file1.swift", path: "/tmp/file1.swift", mutationScore: 66, appliedOperators: [
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/file1.swift", position: .firstPosition),
                                                    testSuiteOutcome: .failed),
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/file1.swift", position: .firstPosition),
                                                    testSuiteOutcome: .failed),
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/file1.swift", position: .firstPosition),
                                                    testSuiteOutcome: .passed)
        ])
    }

    static var expectedFileReport4: MuterTestReport.FileReport {
        return .init(fileName: "file2.swift", path: "/tmp/file2.swift", mutationScore: 100, appliedOperators: [
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .removeSideEffects, filePath: "/tmp/file2.swift", position: .firstPosition),
                                                    testSuiteOutcome: .failed),
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .removeSideEffects, filePath: "/tmp/file2.swift", position: .firstPosition),
                                                    testSuiteOutcome: .failed)
        ])
    }

    static var expectedFileReport5: MuterTestReport.FileReport {
        return .init(fileName: "file3.swift", path: "/tmp/file3.swift", mutationScore: 33, appliedOperators: [
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/file3.swift", position: .firstPosition),
                                                    testSuiteOutcome: .failed),
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/file3.swift", position: .firstPosition),
                                                    testSuiteOutcome: .passed),
            MuterTestReport.AppliedMutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/file3.swift", position: .firstPosition),
                                                    testSuiteOutcome: .passed)
        ])
    }
}
