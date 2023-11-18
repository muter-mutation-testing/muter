import Foundation
@testable import muterCore
import SwiftParser
import SwiftSyntax
import TestingExtensions

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
        mutationSnapshot: MutationOperator.Snapshot = .make(),
        testSuiteOutcome: TestSuiteOutcome = .passed
    ) -> Self {
        Self(
            mutationPoint: mutationPoint,
            mutationSnapshot: mutationSnapshot,
            testSuiteOutcome: testSuiteOutcome
        )
    }
}

extension MutationOperator.Snapshot {
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
        snapshot: MutationOperator.Snapshot = .null,
        originalProjectDirectoryUrl: URL = URL(fileURLWithPath: ""),
        tempDirectoryURL: URL = URL(fileURLWithPath: "")
    ) -> Self {
        Self(
            testSuiteOutcome: testSuiteOutcome,
            mutationPoint: point,
            mutationSnapshot: snapshot,
            originalProjectDirectoryUrl: originalProjectDirectoryUrl,
            tempDirectoryURL: tempDirectoryURL
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
        mutationSnapshot: MutationOperator.Snapshot = .null,
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
        mutationOperatorsList: MutationOperatorList = [],
        skipCoverage: Bool = false,
        skipUpdateCheck: Bool = false,
        configurationURL: URL? = nil
    ) -> Self {
        .init(
            filesToMutate: filesToMutate,
            reportFormat: reportFormat,
            reportURL: reportURL,
            mutationOperatorsList: mutationOperatorsList,
            skipCoverage: skipCoverage,
            skipUpdateCheck: skipUpdateCheck,
            configurationURL: configurationURL
        )
    }
}

typealias SchemataMutationMappings = (source: String, schemata: MutationSchemata)

extension SchemataMutationMapping {
    static func make(
        filePath: String = "",
        _ mappings: SchemataMutationMappings...
    ) throws -> SchemataMutationMapping {
        let schemataMutationMapping = SchemataMutationMapping(filePath: filePath)

        for (source, schemata) in mappings {
            let codeBlockSyntax = try sourceCode(source).statements

            schemata.forEach { schema in
                schemataMutationMapping.add(codeBlockSyntax, schema)
            }
        }

        return schemataMutationMapping
    }
}

extension MutationSchema {
    static func make(
        filePath: String = "",
        mutationOperatorId: MutationOperator.Id = .ror,
        syntaxMutation: String = "",
        position: MutationPosition = .null,
        snapshot: MutationOperator.Snapshot = .null
    ) throws -> MutationSchema {
        try MutationSchema(
            filePath: filePath,
            mutationOperatorId: mutationOperatorId,
            syntaxMutation: sourceCode(syntaxMutation).statements,
            position: position,
            snapshot: snapshot
        )
    }
}

func sourceCode(
    _ source: String
) throws -> SourceFileSyntax {
    Parser.parse(source: source)
}

extension MuterConfiguration {
    static func fromFixture(at path: String) -> MuterConfiguration? {
        guard let data = FileManager.default.contents(atPath: path),
              let configuration = try? MuterConfiguration(from: data)
        else {
            fatalError("Unable to load a valid Muter configuration file from \(path)")
        }
        return configuration
    }
}

extension MutationPosition {
    static var firstPosition: MutationPosition {
        MutationPosition(utf8Offset: 0, line: 0, column: 0)
    }
}
