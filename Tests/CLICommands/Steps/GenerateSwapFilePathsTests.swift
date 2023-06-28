import XCTest
import SwiftSyntax

@testable import muterCore

final class GenerateSwapFilePathsTests: MuterTestCase {
    private let state = RunCommandState()
    private lazy var sut = GenerateSwapFilePaths()

    func test_muterTempDirectoryCreation() {
        state.sourceCodeByFilePath = ["/folder/file1.swift": SourceFileSyntax.makeBlankSourceFile(),
                                      "/folder/file2.swift": SourceFileSyntax.makeBlankSourceFile(),]
        state.tempDirectoryURL = URL(fileURLWithPath: "/workspace")

        _ = sut.run(with: state)

        XCTAssertEqual(fileManager.methodCalls, [
            "createDirectory(atPath:withIntermediateDirectories:attributes:)"
        ])

        XCTAssertEqual(fileManager.createsIntermediates, [true])
        XCTAssertEqual(fileManager.paths, ["/workspace/muter_tmp"])
    }

    func test_swapMappingGeneration() throws {
        state.sourceCodeByFilePath = ["/folder/file1.swift": SourceFileSyntax.makeBlankSourceFile(),
                                      "/folder/file2.swift": SourceFileSyntax.makeBlankSourceFile(),]
        state.tempDirectoryURL = URL(fileURLWithPath: "/workspace")

        let result = try XCTUnwrap(sut.run(with: state).get())

        XCTAssertEqual(result, [
            .swapFilePathGenerated([
                "/folder/file1.swift": "/workspace/muter_tmp/file1.swift",
                "/folder/file2.swift": "/workspace/muter_tmp/file2.swift",
            ])
        ])
    }

    func test_failure() {
        fileManager.errorToThrow = TestingError.stub
        state.tempDirectoryURL = URL(fileURLWithPath: "~/workspace")

        let result = sut.run(with: state)

        guard case let .failure(.unableToCreateSwapFileDirectory(reason: reason)) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        XCTAssertFalse(reason.isEmpty)
    }

    func test_swapFilesPathGeneratesMapping() {
        let paths = ["some/path/to/aFile", "some/path/to/anotherFile"]
        let swapFileDirectory = "~"
        let expectedMapping = ["some/path/to/aFile": "~/aFile",
                               "some/path/to/anotherFile": "~/anotherFile",]

        let actualMapping = sut.swapFilePaths(forFilesAt: paths, using: swapFileDirectory)

        XCTAssertEqual(actualMapping, expectedMapping)
    }

    func test_individualSwapFilesPathMap() {
        let swapFileDirectory = "/some/path/working_directory"

        let firstSwapFilePath = sut.swapFilePath(
            forFileAt: "/some/path/file.swift",
            using: swapFileDirectory
        )

        XCTAssertEqual(firstSwapFilePath, "/some/path/working_directory/file.swift")

        let secondSwapFilePath = sut.swapFilePath(
            forFileAt: "/some/path/deeper/file.swift",
            using: swapFileDirectory
        )

        XCTAssertEqual(secondSwapFilePath, "/some/path/working_directory/file.swift")

        let swapFilePathWithSpaces = sut.swapFilePath(
            forFileAt: "a path with spaces in its name",
            using: swapFileDirectory
        )

        XCTAssertEqual(swapFilePathWithSpaces, "/some/path/working_directory/a path with spaces in its name")

    }
}
