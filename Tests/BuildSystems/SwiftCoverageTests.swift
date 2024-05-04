@testable import muterCore
import TestingExtensions
import XCTest

final class SwiftCoverageTests: MuterTestCase {
    private let sut = SwiftCoverage()

    private var coverageThreshold: Double = 0
    private lazy var muterConfiguration = MuterConfiguration(
        executable: "/path/to/swift",
        arguments: [],
        coverageThreshold: coverageThreshold
    )

    func test_runWithCoverageEnable() {
        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(
            process.executableURL?.path,
            "/path/to/swift"
        )

        XCTAssertEqual(
            process.arguments, [
                "--build-path",
                ".build",
                "--enable-code-coverage",
            ]
        )
    }

    func test_whenCoverageCommandSucceeds_thenFindBinaryPath() {
        process.stdoutToBeReturned = "something"

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(
            process.arguments, [
                "build",
                "--show-bin-path",
            ]
        )
    }

    func test_whenBinaryPathCommandSucceeds_thenFindTestArtifacts() {
        process.stdoutToBeReturned = "something"
        process.stdoutToBeReturned = "/path/to/binary"

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(
            process.executableURL?.path,
            "/usr/bin/find"
        )

        XCTAssertEqual(
            process.arguments, [
                "/path/to/binary",
                "-name",
                "*.xctest",
            ]
        )
    }

    #if os(Linux)
    func test_whenFindTestArtifactsCommandSucceeds_thenGenerateCoverageTable() {
        process.stdoutToBeReturned = "something"
        process.stdoutToBeReturned = "/path/to/binary"
        process.stdoutToBeReturned = "/path/to/testArtifact"
        process.stdoutToBeReturned = "/path/to/llvm-cov"

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(
            process.executableURL?.path,
            "/path/to/llvm-cov"
        )

        XCTAssertEqual(
            process.arguments, [
                "report",
                "/path/to/testArtifact",
                "-instr-profile",
                "/path/to/binary/codecov/default.profdata",
                "--ignore-filename-regex=.build|Tests",
            ]
        )
    }
    #else

    func test_whenFindTestArtifactsCommandSucceeds_thenGenerateCoverageTable() {
        process.stdoutToBeReturned = "something"
        process.stdoutToBeReturned = "/path/to/binary"
        process.stdoutToBeReturned = "/path/to/testArtifact"
        process.stdoutToBeReturned = "/path/to/xcrun"

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(
            process.executableURL?.path,
            "/path/to/xcrun"
        )

        XCTAssertEqual(
            process.arguments, [
                "llvm-cov",
                "report",
                "/path/to/testArtifact/Contents/MacOS/testArtifact",
                "-instr-profile",
                "/path/to/binary/codecov/default.profdata",
                "--ignore-filename-regex=.build|Tests",
            ]
        )
    }
    #endif

    func test_whenGenerateCoverageTableCommandSucceeds_thenParseProjectCoverage() throws {
        process.stdoutToBeReturned = "something"
        process.stdoutToBeReturned = "/path/to/binary"
        process.stdoutToBeReturned = "/path/to/testArtifact"
        process.stdoutToBeReturned = "/path/to/xcrun"
        process.stdoutToBeReturned = loadFixture("logFromllvm-cov.txt")

        let coverage = try XCTUnwrap(sut.run(with: muterConfiguration).get())

        XCTAssertEqual(
            coverage,
            .make(
                percent: 78,
                filesWithoutCoverage: [
                    "CLICommands/MuterError.swift",
                    "Extensions/Nullable.swift",
                    "Extensions/ProgressExtensions.swift",
                    "MutationTesting/MutationTestingAbortReason.swift",
                    "Muter.swift",
                ]
            )
        )
    }

    func test_ignoreFilesLessThanCoverageThreshold() throws {
        process.stdoutToBeReturned = "something"
        process.stdoutToBeReturned = "/path/to/binary"
        process.stdoutToBeReturned = "/path/to/testArtifact"
        process.stdoutToBeReturned = "/path/to/xcrun"
        process.stdoutToBeReturned = loadFixture("logFromllvm-cov.txt")

        coverageThreshold = 50

        let coverage = try XCTUnwrap(sut.run(with: muterConfiguration).get())

        XCTAssertEqual(
            coverage,
            .make(
                percent: 78,
                filesWithoutCoverage: [
                    "CLICommands/MuterError.swift",
                    "CLICommands/RunCommand/Run.swift",
                    "Extensions/Nullable.swift",
                    "Extensions/ProgressExtensions.swift",
                    "MutationTesting/MutationTestingAbortReason.swift",
                    "MutationTesting/MutationTestingIODelegate.swift",
                    "Muter.swift",
                    "TestReporting/PlainText/PlainTextReporter.swift",
                    "TestReporting/Reporter.swift",
                ]
            )
        )
    }

    func test_functionCoverage() throws {
        process.stdoutToBeReturned = "/build/directory"
        process.stdoutToBeReturned = "/path/to/testExecutable.xctest"
        process.stdoutToBeReturned = "/path/to/testBinary"
        process.stdoutToBeReturned = "/path/to/coverage.profdata"
        process.stdoutToBeReturned = "/path/to/llvm-cov"
        process.stdoutToBeReturned = loadFixture("llvmCovExport.json")

        let functionsCoverage = sut.functionsCoverage(muterConfiguration)

        XCTAssertEqual(
            functionsCoverage.regionsForFile("/path/to/file.swift"), [
                .make(
                    lineStart: 14,
                    columnStart: 80,
                    lineEnd: 24,
                    columnEnd: 4,
                    executionCount: 0
                ),
            ]
        )
    }
}
