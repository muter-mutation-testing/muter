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
                "--enable-code-coverage",
            ]
        )
    }

    func test_whenCoverageCommandSucceeds_thenFindBinaryPath() {
        process.enqueueStdOut("something")

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(
            process.executableURL?.path,
            "/path/to/swift"
        )

        XCTAssertEqual(
            process.arguments, [
                "build",
                "--show-bin-path"
            ]
        )
    }

    func test_whenBinaryPathCommandSucceeds_thenFindTestArtifacts() {
        process.enqueueStdOut(
            "something",
            "/path/to/binary"
        )

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(
            process.executableURL?.path,
            "/usr/bin/find"
        )

        XCTAssertEqual(
            process.arguments, [
                "/path/to/binary",
                "-name",
                "*.xctest"
            ]
        )
    }

    func test_whenFindTestArtifactsCommandSucceeds_thenGenerateCoverageTable() {
        process.enqueueStdOut(
            "something",
            "/path/to/binary",
            "/path/to/testArtifact"
        )

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(
            process.executableURL?.path,
            "/usr/bin/xcrun"
        )

        XCTAssertEqual(
            process.arguments, [
                "llvm-cov",
                "report",
                "/path/to/testArtifact/Contents/MacOS/testArtifact",
                "-instr-profile",
                "/path/to/binary/codecov/default.profdata",
                "--ignore-filename-regex=.build|Tests"
            ]
        )
    }

    func test_whenGenerateCoverageTableCommandSucceeds_thenParseProjectCoverage() throws {
        process.enqueueStdOut(
            "something",
            "/path/to/binary",
            "/path/to/testArtifact",
            loadLLVMCovLog()
        )
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
        process.enqueueStdOut(
            "something",
            "/path/to/binary",
            "/path/to/testArtifact",
            loadLLVMCovLog()
        )
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

    private func loadLLVMCovLog() -> String {
        guard let data = FileManager.default
            .contents(atPath: "\(fixturesDirectory)/logFromllvm-cov.txt"),
            let string = String(data: data, encoding: .utf8)
        else {
            fatalError("Unable to load reportfor testing")
        }

        return string
    }
}
