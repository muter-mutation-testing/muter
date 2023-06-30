@testable import muterCore

class FileReportProvider {

    static var expectedFileReport1: MuterTestReport.FileReport {
        .init(fileName: "a module.swift", path: "/tmp/a module.swift", mutationScore: 100, appliedOperators: [
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/a module.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .failed
            ),
        ])
    }

    static var expectedFileReport2: MuterTestReport.FileReport {
        .init(fileName: "file 4.swift", path: "/tmp/file 4.swift", mutationScore: 0, appliedOperators: [
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file 4.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .passed
            ),
        ])
    }

    static var expectedFileReport3: MuterTestReport.FileReport {
        .init(fileName: "file1.swift", path: "/tmp/file1.swift", mutationScore: 66, appliedOperators: [
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .failed
            ),
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .failed
            ),
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .passed
            ),
        ])
    }

    static var expectedFileReport4: MuterTestReport.FileReport {
        .init(fileName: "file2.swift", path: "/tmp/file2.swift", mutationScore: 100, appliedOperators: [
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .removeSideEffects,
                    filePath: "/tmp/file2.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .failed
            ),
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .removeSideEffects,
                    filePath: "/tmp/file2.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .failed
            ),
        ])
    }

    static var expectedFileReport5: MuterTestReport.FileReport {
        .init(fileName: "file3.swift", path: "/tmp/file3.swift", mutationScore: 33, appliedOperators: [
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .failed
            ),
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .passed
            ),
            MuterTestReport.AppliedMutationOperator.make(
                mutationPoint: MutationPoint.make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition
                ),
                mutationSnapshot: .make(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                testSuiteOutcome: .passed
            ),
        ])
    }
}
