import Quick
import Nimble
import Commandant
import Foundation
@testable import muterCore

@available(OSX 10.13, *)
class RunCommandDelegateSpec: QuickSpec {
    override func spec() {

        describe("RunCommandDelegate") {
            var fileManagerSpy: FileManagerSpy!
            var runCommandDelegate: RunCommandDelegate!

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

