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

                let swapFilePathWithSpaces = swapFilePath(forFileAt: "a path with spaces in its name", using: workingDirectory)
                expect(swapFilePathWithSpaces).to(equal("/some/path/working_directory/a path with spaces in its name"))
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
