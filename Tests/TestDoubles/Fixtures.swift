@testable import muterCore

import TestingExtensions
import Foundation
import SwiftSyntax

extension MuterTestReport {
    static func make(
        outcome: MutationTestOutcome = .make()
    ) -> MuterTestReport {
        .init(from: outcome)
    }
}

extension MuterTestReport.AppliedMutationOperator {
    static func make(
        mutationPoint: MutationPoint = .make(),
        mutationSnapshot: MutationOperatorSnapshot = .make(),
        testSuiteOutcome: TestSuiteOutcome = .passed
    ) -> Self {
        Self(
            mutationPoint: mutationPoint,
            mutationSnapshot: mutationSnapshot,
            testSuiteOutcome: testSuiteOutcome
        )
    }
}

extension MutationOperatorSnapshot {
    static func make(
        before: String = "",
        after: String = "",
        description: String = ""
    ) -> Self {
        Self(
            before: before,
            after: after,
            description: description
        )
    }
}

extension MutationTestOutcome {
    static func make(
        mutations: [Mutation] = [],
        coverage: Coverage = .null
    ) -> MutationTestOutcome {
        MutationTestOutcome(
            mutations: mutations,
            coverage: coverage
        )
    }
}

extension MutationTestOutcome.Mutation {
    static func make(
        testSuiteOutcome: TestSuiteOutcome = .passed,
        point: MutationPoint = .make(),
        snapshot: MutationOperatorSnapshot = .null,
        originalProjectDirectoryUrl: URL = URL(fileURLWithPath: "")
    ) -> Self {
        Self(
            testSuiteOutcome: testSuiteOutcome,
            mutationPoint: point,
            mutationSnapshot: snapshot,
            originalProjectDirectoryUrl: originalProjectDirectoryUrl
        )
    }
}

extension MuterTestReport.FileReport {
    static func make(
        name: String,
        path: String,
        mutationScore: Int,
        appliedOperators: [MuterTestReport.AppliedMutationOperator]
    ) -> Self {
        Self(
            fileName: name,
            path: path,
            mutationScore: mutationScore,
            appliedOperators: appliedOperators
        )
    }
}

extension MuterTestReport.AppliedMutationOperator {
    static func make(
        mutationOperator: MutationOperator.Id = .logicalOperator,
        position: SwiftSyntax.SourceLocation = .init(integerLiteral: 0),
        mutationSnapshot: MutationOperatorSnapshot = .null,
        testOutcome: TestSuiteOutcome = .passed
    ) -> Self {
        Self(
            mutationPoint: .make(
                mutationOperatorId: mutationOperator,
                filePath: "filePath",
                position: MutationPosition(sourceLocation: position)
            ), mutationSnapshot: mutationSnapshot,
            testSuiteOutcome: testOutcome
        )
    }
}

extension MutationPoint {
    static func make(
        mutationOperatorId: MutationOperator.Id = .logicalOperator,
        filePath: String = "",
        position: MutationPosition = 10
    ) -> Self {
        Self(
            mutationOperatorId: mutationOperatorId,
            filePath: filePath,
            position: position
        )
    }
}

func nextMutationOperator(
    _ index: Int
) -> MutationOperator.Id {
    MutationOperator.Id.allCases[circular: index]
}

func nextMutationTestOutcome(
    _ index: Int
) -> TestSuiteOutcome {
    TestSuiteOutcome.allCases[circular: index]
}

extension MutationPosition: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(
            sourceLocation: .init(integerLiteral: value)
        )
    }
}

extension SwiftSyntax.SourceLocation: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(line: value, column: value, offset: value, file: "")
    }
}

extension Array {
    subscript(circular index: Int) -> Element {
        self[Swift.max(index, 1) % count]
    }
}

extension Coverage {
    static func make(
        percent: Int = 0,
        filesWithoutCoverage: [FilePath] = []
    ) -> Coverage {
        Coverage(
            percent: percent,
            filesWithoutCoverage: filesWithoutCoverage
        )
    }
}

extension RunOptions {
    static func make(
        filesToMutate: [String] = [],
        reportFormat: ReportFormat = .plain,
        reportURL: URL? = nil,
        skipCoverage: Bool = false,
        logger: Logger = .init()
    ) -> Self {
        .init(
            filesToMutate: filesToMutate,
            reportFormat: reportFormat,
            reportURL: reportURL,
            skipCoverage: skipCoverage,
            logger: logger
        )
    }
}
