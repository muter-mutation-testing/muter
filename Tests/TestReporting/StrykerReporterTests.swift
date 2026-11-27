@testable import muterCore
import TestingExtensions
import XCTest

final class StrykerReporterTests: MuterTestCase {
    private let projectURL = URL(fileURLWithPath: "/user/project")
    private let mutatedProjectURL = URL(fileURLWithPath: "/tmp/project_mutated")

    private let sources = [
        "/user/project/Sources/A.swift": "func a(x: Int) -> Bool {\n    return x > 0 && true\n}\n",
        "/user/project/Sources/B.swift": "func b() {\n    let é = 1\n    print(é == 1)\n}\n",
    ]

    private func mutation(
        _ outcome: TestSuiteOutcome,
        _ id: MutationOperator.Id,
        file: String,
        line: Int,
        column: Int,
        snapshot: MutationOperator.Snapshot,
        range: MutationRange? = nil,
        replacement: String? = nil,
        failedTests: Int? = nil
    ) -> MutationTestOutcome.Mutation {
        .make(
            testSuiteOutcome: outcome,
            point: MutationPoint(
                mutationOperatorId: id,
                filePath: "/tmp/project_mutated/Sources/\(file)",
                position: MutationPosition(line: line, column: column)
            ),
            snapshot: snapshot,
            originalProjectDirectoryUrl: projectURL,
            mutatedProjectDirectoryURL: mutatedProjectURL,
            failedTests: failedTests,
            range: range,
            replacement: replacement
        )
    }

    private func range(_ line: Int, _ start: Int, _ end: Int) -> MutationRange {
        MutationRange(start: .init(line: line, column: start), end: .init(line: line, column: end))
    }

    private func report(_ mutations: [MutationTestOutcome.Mutation]) -> StrykerReport {
        StrykerReport(outcome: .make(mutations: mutations), readFile: { self.sources[$0] })
    }

    func test_reportHasTheFilesSourcesAndMutantsInSourceOrder() {
        let report = report([
            mutation(
                .passed, .logicalOperator, file: "A.swift", line: 2, column: 18,
                snapshot: .make(before: "&&", after: "||", description: "changed && to ||"),
                range: range(2, 18, 20)
            ),
            mutation(
                .failed, .ror, file: "A.swift", line: 2, column: 14,
                snapshot: .make(before: ">", after: "<=", description: "changed > to <="),
                range: range(2, 14, 15),
                failedTests: 2
            ),
        ])

        XCTAssertEqual(report.schemaVersion, "2")
        XCTAssertEqual(report.thresholds, StrykerReport.defaultThresholds)
        XCTAssertEqual(report.projectRoot, "/user/project")
        XCTAssertEqual(report.framework.name, "Muter")
        XCTAssertEqual(report.framework.version, muterCore.version)
        XCTAssertEqual(Array(report.files.keys), ["Sources/A.swift"])
        XCTAssertEqual(report.files["Sources/A.swift"]?.language, "swift")
        XCTAssertEqual(report.files["Sources/A.swift"]?.source, sources["/user/project/Sources/A.swift"])
        XCTAssertEqual(
            report.files["Sources/A.swift"]?.mutants,
            [
                .init(
                    id: "1",
                    mutatorName: "RelationalOperatorReplacement",
                    replacement: "<=",
                    description: "changed > to <=",
                    location: .init(start: .init(line: 2, column: 14), end: .init(line: 2, column: 15)),
                    status: .killed,
                    statusReason: "mutant killed (test failure), 2 tests failed"
                ),
                .init(
                    id: "2",
                    mutatorName: "ChangeLogicalConnector",
                    replacement: "||",
                    description: "changed && to ||",
                    location: .init(start: .init(line: 2, column: 18), end: .init(line: 2, column: 20)),
                    status: .survived,
                    statusReason: "mutant survived"
                ),
            ]
        )
    }

    func test_statusOfEachOutcome() {
        let statuses = TestSuiteOutcome.allCases.map { ($0, StrykerReport.Status($0)) }

        XCTAssertEqual(statuses.map(\.0), [.passed, .failed, .buildError, .runtimeError, .noCoverage, .timeout, .ignored])
        XCTAssertEqual(
            statuses.map(\.1),
            [.survived, .killed, .compileError, .killed, .noCoverage, .timeout, .ignored]
        )
    }

    /// Muter's columns count UTF-8 bytes. The report counts UTF-16 code units, and `é` is 2 bytes but
    /// 1 code unit.
    func test_columnsCountUTF16CodeUnits() {
        let report = report([
            mutation(
                .passed, .ror, file: "B.swift", line: 3, column: 14,
                snapshot: .make(before: "==", after: "!=", description: "changed == to !="),
                range: range(3, 14, 16)
            ),
        ])

        XCTAssertEqual(
            report.files["Sources/B.swift"]?.mutants.first?.location,
            .init(start: .init(line: 3, column: 13), end: .init(line: 3, column: 15))
        )
    }

    /// A mutant from a test plan of an older Muter has no range. Its location is the original code
    /// at its position.
    func test_locationWithoutARangeUsesThePosition() {
        let report = report([
            mutation(
                .passed, .ror, file: "A.swift", line: 2, column: 14,
                snapshot: .make(before: ">", after: "<=", description: "changed > to <=")
            ),
        ])

        XCTAssertEqual(
            report.files["Sources/A.swift"]?.mutants.first?.location,
            .init(start: .init(line: 2, column: 14), end: .init(line: 2, column: 15))
        )
    }

    /// RemoveSideEffects and SwapTernary record the end of the mutated code. Without a range, the
    /// location covers that line up to the end, not the code after it.
    func test_locationWithoutARangeForAnEndPositionUsesItsLine() {
        let report = report([
            mutation(
                .passed, .removeSideEffects, file: "B.swift", line: 3, column: 18,
                snapshot: .make(before: "print(é == 1)", after: "removed line", description: "removed line")
            ),
        ])

        XCTAssertEqual(
            report.files["Sources/B.swift"]?.mutants.first?.location,
            .init(start: .init(line: 3, column: 5), end: .init(line: 3, column: 17))
        )
    }

    func test_removedStatementHasAnEmptyReplacement() {
        let report = report([
            mutation(
                .passed, .removeSideEffects, file: "B.swift", line: 3, column: 18,
                snapshot: .make(before: "print(é == 1)", after: "removed line", description: "removed line"),
                range: range(3, 5, 19)
            ),
        ])

        XCTAssertEqual(report.files["Sources/B.swift"]?.mutants.first?.replacement, "")
    }

    func test_replacementComesFromTheMutantWhenItHasOne() {
        let report = report([
            mutation(
                .passed, .swapTernary, file: "A.swift", line: 2, column: 14,
                snapshot: .make(before: "x ? 1 // one 2", after: "x ? 2 // one 1", description: "swapped ternary operator"),
                range: range(2, 12, 20),
                replacement: "x // the flag\n    ? 2\n    : 1"
            ),
        ])

        XCTAssertEqual(
            report.files["Sources/A.swift"]?.mutants.first?.replacement,
            "x // the flag\n    ? 2\n    : 1"
        )
    }

    /// Muter does not mutate a file with no coverage. Coverage gives its path in the mutated copy,
    /// and the report lists it, with no mutants, by its path in the project.
    func test_filesWithoutCoverageAreInTheReportWithNoMutants() {
        let report = StrykerReport(
            outcome: .make(
                mutations: [
                    mutation(
                        .passed, .ror, file: "A.swift", line: 2, column: 14,
                        snapshot: .make(before: ">", after: "<=", description: "changed > to <="),
                        range: range(2, 14, 15)
                    ),
                ],
                coverage: .make(filesWithoutCoverage: ["/tmp/project_mutated/Sources/B.swift"])
            ),
            readFile: { self.sources[$0] }
        )

        XCTAssertEqual(report.files.keys.sorted(), ["Sources/A.swift", "Sources/B.swift"])
        XCTAssertEqual(report.files["Sources/B.swift"]?.mutants, [])
        XCTAssertEqual(report.files["Sources/B.swift"]?.source, sources["/user/project/Sources/B.swift"])
    }

    func test_ignoredMutantsAreInTheReport() {
        let report = report([
            mutation(
                .ignored, .ror, file: "A.swift", line: 2, column: 14,
                snapshot: .make(before: ">", after: "<=", description: "changed > to <="),
                range: range(2, 14, 15)
            ),
        ])

        XCTAssertEqual(report.files["Sources/A.swift"]?.mutants.map(\.status), [.ignored])
        XCTAssertEqual(report.files["Sources/A.swift"]?.mutants.map(\.statusReason), ["ignored (muter:disable)"])
    }

    func test_jsonUsesTheSchemaNames() throws {
        let json = StrykerReporter(readFile: { self.sources[$0] }).report(
            from: .make(mutations: [
                mutation(
                    .timeout, .ror, file: "A.swift", line: 2, column: 14,
                    snapshot: .make(before: ">", after: "<=", description: "changed > to <="),
                    range: range(2, 14, 15)
                ),
            ])
        )

        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(json.data(using: .utf8))) as? [String: Any]
        )
        XCTAssertEqual(object["schemaVersion"] as? String, "2")
        XCTAssertEqual((object["thresholds"] as? [String: Int]) ?? [:], ["high": 80, "low": 60])
        let files = try XCTUnwrap(object["files"] as? [String: [String: Any]])
        let mutant = try XCTUnwrap((files["Sources/A.swift"]?["mutants"] as? [[String: Any]])?.first)
        XCTAssertEqual(mutant["status"] as? String, "Timeout")
        XCTAssertEqual(mutant["mutatorName"] as? String, "RelationalOperatorReplacement")
        let location = try XCTUnwrap(mutant["location"] as? [String: [String: Int]])
        XCTAssertEqual(location["start"], ["line": 2, "column": 14])
        XCTAssertEqual(location["end"], ["line": 2, "column": 15])
    }

    func test_formatName() {
        XCTAssertEqual(ReportFormat(rawValue: "stryker"), .stryker)
        XCTAssertTrue(ReportFormat.stryker.reporter is StrykerReporter)
    }
}
