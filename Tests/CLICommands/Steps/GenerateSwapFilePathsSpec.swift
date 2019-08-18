import Quick
import Nimble
import Foundation
import SwiftSyntax
@testable import muterCore

class GenerateSwapFilePathsSpec: QuickSpec {
    override func spec() {

        var state: RunCommandState!
        var result: Result<[RunCommandState.Change], MuterError>!
        var fileManagerSpy: FileManagerSpy!
        var generateSwapFilePaths: GenerateSwapFilePaths!

        describe("the SwapFilePathGeneration step") {
            beforeEach {
                fileManagerSpy = FileManagerSpy()
                generateSwapFilePaths = GenerateSwapFilePaths(fileManager: fileManagerSpy)
            }

            context("when it creates a swap file directory and generates the paths") {
                beforeEach {
                    state = RunCommandState()
                    state.sourceCodeByFilePath = ["/folder/file1.swift": SyntaxFactory.makeBlankSourceFile(),
                                                  "/folder/file2.swift": SyntaxFactory.makeBlankSourceFile()]
                    state.tempDirectoryURL = URL(fileURLWithPath: "/workspace")
                    result = generateSwapFilePaths.run(with: state)
                }

                it("creates a new directory called muter_tmp in the temporary directory") {expect(fileManagerSpy.methodCalls).to(equal(["createDirectory(atPath:withIntermediateDirectories:attributes:)"]))
                    expect(fileManagerSpy.createsIntermediates).to(equal([true]))
                    expect(fileManagerSpy.paths).to(equal(["/workspace/muter_tmp"]))
                }

                it("returns a swap file mapping so later steps can use it without needing to generate it") {
                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }

                    expect(stateChanges) == [
                        .swapFilePathGenerated([
                            "/folder/file1.swift": "/workspace/muter_tmp/file1.swift",
                            "/folder/file2.swift":"/workspace/muter_tmp/file2.swift"
                        ])
                    ]
                }
            }

            context("when it creates a swap file directory and generates the paths") {

                beforeEach {
                    fileManagerSpy.errorToThrow = TestingError.stub
                    state = RunCommandState()
                    state.tempDirectoryURL = URL(fileURLWithPath: "~/workspace")
                    result = generateSwapFilePaths.run(with: state)
                }

                it("cascades a failure explaining why it wasn't able to generate a swap file directory") {
                    guard case .failure(_) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                }
            }
        }

        describe("SwapFilePathGeneration.swapFilePaths") {
            it("generates a mapping between swap files and their original file paths") {
                let paths = ["some/path/to/aFile", "some/path/to/anotherFile"]
                let swapFileDirectory = "~"
                let expectedMapping = ["some/path/to/aFile": "~/aFile",
                                       "some/path/to/anotherFile": "~/anotherFile"]

                expect(generateSwapFilePaths.swapFilePaths(forFilesAt: paths, using: swapFileDirectory)).to(equal(expectedMapping))
            }
        }

        describe("SwapFilePathGeneration.swapFilePath") {
            it("generates individual swap file paths") {
                let swapFileDirectory = "/some/path/working_directory"

                let firstSwapFilePath = generateSwapFilePaths.swapFilePath(forFileAt: "/some/path/file.swift", using: swapFileDirectory)
                expect(firstSwapFilePath).to(equal("/some/path/working_directory/file.swift"))

                let secondSwapFilePath = generateSwapFilePaths.swapFilePath(forFileAt: "/some/path/deeper/file.swift", using: swapFileDirectory)
                expect(secondSwapFilePath).to(equal("/some/path/working_directory/file.swift"))

                let swapFilePathWithSpaces = generateSwapFilePaths.swapFilePath(forFileAt: "a path with spaces in its name", using: swapFileDirectory)
                expect(swapFilePathWithSpaces).to(equal("/some/path/working_directory/a path with spaces in its name"))
            }
        }
    }
}
