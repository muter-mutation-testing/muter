import XCTest
import TestingExtensions

@testable import muterCore

final class SwiftCoverageTests: MuterTestCase {
    private let sut = SwiftCoverage()

    private let muterConfiguration = MuterConfiguration(
        executable: "/path/to/swift",
        arguments: []
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
        process.stdoutToBeReturned = ""

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
        process.stdoutToBeReturned = ""
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
                "*.xctest"
            ]
        )
    }
    
    func test_whenFindTestArtifactsCommandSucceeds_thenGenerateCoverageTable() {
        process.stdoutToBeReturned = ""
        process.stdoutToBeReturned = "/path/to/binary"
        process.stdoutToBeReturned = "/path/to/testArtifact"

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
                ".build/debug/codecov/default.profdata",
                "--ignore-filename-regex=.build|Tests"
            ]
        )
    }
    
    func test_whenGenerateCoverageTableCommandSucceeds_thenParseProjectCoverage() throws {
        process.stdoutToBeReturned = ""
        process.stdoutToBeReturned = "/path/to/binary"
        process.stdoutToBeReturned = "/path/to/testArtifact"
        process.stdoutToBeReturned = loadLLVMCovLog()

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
    
    private func loadLLVMCovLog() -> String {
        guard let data = FileManager.default.contents(atPath: "\(SwiftCoverageTests().fixturesDirectory)/logFromllvm-cov.txt"),
              let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load reportfor testing")
        }
        
        return string
    }
}
