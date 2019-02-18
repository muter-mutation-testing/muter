import Quick
import Nimble
import Commandant
import Foundation
import muterCore

@available(OSX 10.13, *)
class RunCommandDelegateSpec: QuickSpec {
    override func spec() {

        describe("RunCommandDelegate") {
            var fileManagerSpy: FileManagerSpy!
            var runCommandDelegate: RunCommandDelegate!

            describe("backing up a project into a temporary directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.tempDirectory = URL(string: "/tmp/")!
                    runCommandDelegate = RunCommandDelegate(fileManager: fileManagerSpy)

                    runCommandDelegate.backupProject(in: "/some/projectName")
                }

                it("creates a temp directory to store a copy of the code under test") {
                    expect(runCommandDelegate.temporaryDirectoryURL).to(equal("/tmp/projectName"))

                    expect(fileManagerSpy.searchPathDirectories).to(equal([.itemReplacementDirectory]))
                    expect(fileManagerSpy.domains).to(equal([.userDomainMask]))
                    expect(fileManagerSpy.paths).to(equal(["/some/projectName"]))
                }

                it("copies the project to the temp directory") {
                    expect(fileManagerSpy.copyPaths.first?.source).to(equal("/some/projectName"))
                    expect(fileManagerSpy.copyPaths.first?.dest).to(equal("/tmp/projectName"))
                    expect(fileManagerSpy.copyPaths).to(haveCount(1))
                }

                it("copies the project after creating the temp directory") {
                    expect(fileManagerSpy.methodCalls).to(equal(["url(for:in:appropriateFor:create:)",
                                                                 "copyItem(atPath:toPath:)"]))
                }
            }

            describe("saving mutation test reports") {
                afterEach {
                    try? FileManager.default.removeItem(atPath: "\(self.rootTestDirectory)/muterReport.json")
                }

                it("saves a JSON version of the generated mutation test report to a specified directory") {
                    let realFileManager = FileManager.default
                    let outcome = MutationTestOutcome(testSuiteOutcome: .failed,
                                                      appliedMutation: .negateConditionals,
                                                      filePath: "some path",
                                                      position: .firstPosition)
                    let report = MuterTestReport(from: [outcome])

                    RunCommandDelegate(fileManager: realFileManager).saveReport(report, to: self.rootTestDirectory)

                    guard let _ = realFileManager.contents(atPath: "\(self.rootTestDirectory)/muterReport.json") else {
                        fail("Expected a JSON file to be written to \(self.rootTestDirectory)/muterReport.json")
                        return
                    }
                }
            }

            describe("loading a configuration") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.currentDirectoryPathToReturn = "this can be anything"
                }
                context("when it's a valid configuration file") {
                    beforeEach {
                        fileManagerSpy.fileContentsToReturn = """
                        {
                        "executable": "/something",
                        "arguments": ["argument"],
                        }
                        """.data(using: .utf8)

                        runCommandDelegate = RunCommandDelegate(fileManager: fileManagerSpy)

                    }

                    it("loads a configuration from the current directory") {
                        let configuration = runCommandDelegate.loadConfiguration()
                        expect(configuration).to(equal(MuterConfiguration(executable: "/something", arguments: ["argument"], excludeList: [])))
                    }
                }
                context("when it's an invalid configuration file") {
                    beforeEach {
                        fileManagerSpy.fileContentsToReturn = """
                        {
                        "executable":
                        }
                        """.data(using: .utf8)

                        runCommandDelegate = RunCommandDelegate(fileManager: fileManagerSpy)
                    }

                    it("returns nil") {
                        expect(runCommandDelegate.loadConfiguration()).to(beNil())
                    }
                }
            }
        }
    }
}

