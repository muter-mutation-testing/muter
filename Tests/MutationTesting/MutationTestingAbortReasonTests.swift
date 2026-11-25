@testable import muterCore
import TestingExtensions
import XCTest

final class MutationTestingAbortReasonTests: MuterTestCase {
    private let mutatedFilePath = "/project/Sources/Calc/Calc.swift"

    func test_whenBaselineFailedToCompileAMutatedFile_thenBlameMuterAndNameTheFileAndError() {
        let log = """
        Building for debugging...
        /project_mutated/Sources/Calc/Calc.swift:8:24: error: expected expression after operator
        error: fatalError
        """

        let description = MutationTestingAbortReason.baselineTestFailed(
            log: log,
            mutatedFilePaths: [mutatedFilePath]
        ).description

        XCTAssertTrue(
            description.contains("Calc.swift:8:24: error: expected expression after operator"),
            description
        )
        XCTAssertTrue(description.contains("bug in Muter's own rewriting"), description)
        XCTAssertFalse(
            description.contains("misconfiguring"),
            "A mutant that doesn't compile is Muter's fault, so the message must not point at the user's configuration:\n\(description)"
        )
    }

    func test_whenBaselineFailedWithACompileErrorInAFileMuterDidNotMutate_thenKeepTheConfigurationHint() {
        let log = """
        /project_mutated/Tests/CalcTests/CalcTests.swift:4:1: error: no such module 'Calc'
        """

        let description = MutationTestingAbortReason.baselineTestFailed(
            log: log,
            mutatedFilePaths: [mutatedFilePath]
        ).description

        XCTAssertTrue(description.contains("misconfiguring"), description)
        XCTAssertFalse(description.contains("bug in Muter's own rewriting"), description)
        XCTAssertTrue(description.contains("no such module 'Calc'"), description)
    }

    func test_whenBaselineFailedWithATestFailure_thenKeepTheConfigurationHint() {
        let log = """
        Test Case '-[CalcTests.CalcTests test_inRange]' failed (0.001 seconds).
        Executed 2 tests, with 1 failure (0 unexpected) in 0.002 seconds
        """

        let description = MutationTestingAbortReason.baselineTestFailed(
            log: log,
            mutatedFilePaths: [mutatedFilePath]
        ).description

        XCTAssertTrue(description.contains("misconfiguring"), description)
        XCTAssertTrue(description.contains("test_inRange"), description)
    }

    func test_whenThereIsNoLog_thenSayThereIsNoneRatherThanPrintingAnEmptySection() {
        let description = MutationTestingAbortReason.baselineTestFailed(
            log: "",
            mutatedFilePaths: [mutatedFilePath]
        ).description

        XCTAssertTrue(description.contains("captured no output at all"), description)
        XCTAssertFalse(
            description.contains("Here's the log"),
            "Promising a log and then printing nothing leaves the user with no evidence:\n\(description)"
        )
    }

    func test_compilerErrorParsing() {
        let log = """
        Building for debugging...
        /project/Calc.swift:8:24: error: expected expression after operator
        /project/Calc.swift:9:1: warning: unused variable
        /project/Calc.swift:10: error: missing a column
        error: fatalError
        note: /project/Other.swift:1:1: error: quoted inside a note
        """

        XCTAssertEqual(
            CompilerError.all(in: log),
            [
                CompilerError(
                    filePath: "/project/Calc.swift",
                    line: 8,
                    column: 24,
                    message: "expected expression after operator"
                ),
            ]
        )
    }
}
