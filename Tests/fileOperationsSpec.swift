@testable import muterCore
import Quick
import Nimble

class FileOperationSpec: QuickSpec {
    override func spec() {
        describe("Swap File Path Generation") {

            it("generates a mapping between swap files and their original file paths") {
                let paths = ["some/path/to/aFile", "some/path/to/anotherFile"]
                let workingDirectory = "~"
                let expectedMapping = ["some/path/to/aFile": "~/aFile",
                                       "some/path/to/anotherFile": "~/anotherFile"]

                expect(swapFilePaths(forFilesAt: paths, using: workingDirectory)).to(equal(expectedMapping))

            }

            it("generates swap file paths") {
                let workingDirectory = "/some/path/working_directory"

                let firstSwapFilePath = swapFilePath(forFileAt: "/some/path/file.swift", using: workingDirectory)
                expect(firstSwapFilePath).to(equal("/some/path/working_directory/file.swift"))

                let secondSwapFilePath = swapFilePath(forFileAt: "/some/path/deeper/file.swift", using: workingDirectory)
                expect(secondSwapFilePath).to(equal("/some/path/working_directory/file.swift"))

                let emptySwapFilePath = swapFilePath(forFileAt: "malformed path that doesn't exist", using: workingDirectory)
                expect(emptySwapFilePath).to(equal(""))
            }
        }

        describe("Swift Source File Discovery") {
            it("discovers Swift files recursively and returns the results alphabetically") {
                let path = "\(self.fixturesDirectory)/FilesToDiscover"
                let discoveredPaths = discoverSourceFiles(inDirectoryAt: path)

                expect(discoveredPaths).to(equal([
                    "\(path)/Directory1/file3.swift",
                    "\(path)/Directory2/Directory3/file6.swift",
                    "\(path)/ExampleApp/ExampleAppCode.swift",
                    "\(path)/file1.swift",
                    "\(path)/file2.swift",
                ]))
            }

            it("discovers Swift files applying a user-provided exclude list") {
                let path = "\(self.fixturesDirectory)/FilesToDiscover"
                let discoveredPaths = discoverSourceFiles(inDirectoryAt: path,
                                                          excludingPathsIn: ["ExampleApp"])
                expect(discoveredPaths).to(equal([
                    "\(path)/Directory1/file3.swift",
                    "\(path)/Directory2/Directory3/file6.swift",
                    "\(path)/file1.swift",
                    "\(path)/file2.swift",
                ]))
            }

            it("discovers 0 Swift files in a directory that doesn't exist") {
                expect(discoverSourceFiles(inDirectoryAt: "I don't exist")).to(beEmpty())
            }

            it("ignores files that aren't Swift files") {
                let path = "\(self.fixturesDirectory)/FilesToDiscover"

                expect(discoverSourceFiles(inDirectoryAt: "\(path)/Directory4")).to(beEmpty())
                expect(discoverSourceFiles(inDirectoryAt: "\(path)/Directory2")).to(equal([
                    "\(path)/Directory2/Directory3/file6.swift",
                ]))
            }
        }

        describe("Working Directory Creation") {
            it("creates a working directory for mutation testing") {
                let fileManagerSpy = FileManagerSpy()
                let workingDirectory = createWorkingDirectory(in: "~/some/path", fileManager: fileManagerSpy)

                expect(workingDirectory).to(equal("~/some/path/muter_tmp"))
                expect(fileManagerSpy.methodCalls).to(equal(["createDirectory(atPath:withIntermediateDirectories:attributes:)"]))
                expect(fileManagerSpy.createsIntermediates).to(equal([true]))
                expect(fileManagerSpy.paths).to(equal(["~/some/path/muter_tmp"]))
            }
        }
    }
}
