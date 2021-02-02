import Quick
import Nimble
import Foundation
@testable import muterCore

class DiscoverFilesWithoutCoverageSpec: QuickSpec {
    override func spec() {
        describe("the DiscoverFilesWithoutCoverage step") {
            var discoverFilesWithoutCoverage: DiscoverFilesWithoutCoverage!
            var state: RunCommandState!
            var process: LaunchableSpy!
            
            beforeEach {
                state = RunCommandState()
                process = LaunchableSpy()
                discoverFilesWithoutCoverage = DiscoverFilesWithoutCoverage(
                    process: process
                )
            }

            describe("when project uses `xcodebuild`") {
                beforeEach {
                    state.muterConfiguration = MuterConfiguration(
                        executable: "/path/to/xcodebuild",
                        arguments: ["arg0", "arg1"]
                    )
                }

                it("should run build command with coverage") {
                    _ = discoverFilesWithoutCoverage.run(with: state)

                    expect(process.executableURL?.absoluteString).to(equal("file:///path/to/xcodebuild"))
                    expect(process.arguments).to(equal(["arg0", "arg1", "-enableCodeCoverage", "YES"]))
                    expect(process.runCalled).to(beTrue())
                    expect(process.waitUntilExitCalled).to(beTrue())
                }
                
                context("when `xcodebuild` ends with success") {
                    beforeEach {
                        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"

                        _ = discoverFilesWithoutCoverage.run(with: state)
                    }

                    it("should execute `xcode-select` command") {
                        expect(process.executableURL?.absoluteString).to(equal("file:///usr/bin/xcode-select"))
                        expect(process.arguments).to(equal(["-p"]))
                    }
                    
                    context("when `xcode-select` ends with success") {
                        beforeEach {
                            process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
                            process.stdoutToBeReturned = "/path/to/xccov"
                            
                            _ = discoverFilesWithoutCoverage.run(with: state)
                        }

                        it("should execute `xccov` command") {
                            expect(process.executableURL?.absoluteString).to(equal("file:///path/to/xccov/usr/bin/xccov"))
                            expect(process.arguments).to(
                                equal(["view", "--report", "--json", "path/to/testResult.xcresult"])
                            )
                        }
                        
                        context("when `xccov` ends with success") {
                            beforeEach {
                                process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
                                process.stdoutToBeReturned = "/path/to/xccov"
                                process.stdoutToBeReturned = coverageData
                            }
                            
                            it("should return files without coverage") {
                                let files = try! discoverFilesWithoutCoverage.run(with: state).get()
                                
                                expect(files).to(equal([
                                    .filesWithoutCoverage(["/path/to/file1.swift"])
                                ]))
                            }
                        }
                    }

                    context("when `xcode-select` ends with error") {
                        beforeEach {
                            process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
                            process.stdoutToBeReturned = ""

                            _ = discoverFilesWithoutCoverage.run(with: state)
                        }

                        it("then dont execute `xccov` command") {
                            expect(process.executableURL?.absoluteString).notTo(contain("xccov"))
                        }
                    }
                }
                
                context("when `xcodebuild` ends with error") {
                    beforeEach {
                        process.stdoutToBeReturned = ""

                        _ = discoverFilesWithoutCoverage.run(with: state)
                    }

                    it("then dont execute xcode-select command") {
                        expect(process.executableURL?.absoluteString).notTo(equal("file:///usr/bin/xcode-select"))
                    }
                }
            }
            
            describe("when project does not use `xcodebuild`") {
                beforeEach {
                    state.muterConfiguration = MuterConfiguration(
                        executable: "/path/to/build-system"
                    )
                }

                it("should return an empty list") {
                    let result = try! discoverFilesWithoutCoverage.run(with: state).get()
                    
                    expect(result).to(haveCount(1))
                    expect(result.first).to(equal(.filesWithoutCoverage([])))
                }
                
                it("should not run build command") {
                    _ = discoverFilesWithoutCoverage.run(with: state)

                    expect(process.runCalled).to(beTrue())
                    expect(process.waitUntilExitCalled).to(beTrue())
                }
            }
        }
    }
}

private class LaunchableSpy: Launchable {
    private let standardOutputStub = StandardOutputStub()
    var stdoutToBeReturned = "" {
        didSet {
            standardOutputStub.dataToBeReturned = stdoutToBeReturned.data(using: .utf8)
        }
    }

    var executableURL: URL?
    var arguments: [String]?
    var standardOutput: Any? {
        get { standardOutputStub }
        set { }
    }
    
    var runCalled = false
    func run() throws {
        runCalled = true
    }
    
    var waitUntilExitCalled = false
    func waitUntilExit() {
        waitUntilExitCalled = true
    }
}

private class StandardOutputStub: StandardOutput {
    private let queue = Queue()
    var dataToBeReturned: Data? {
        didSet {
            queue.enqueue(dataToBeReturned!)
        }
    }
    func data() -> Data? { queue.dequeue() }
}

private class Queue {
    private var contents = [Data]()

    func dequeue() -> Data? {
        contents.isEmpty ? nil : contents.removeFirst()
    }
    
    func enqueue(_ data: Data) {
        contents.append(data)
    }
}

let coverageData =
"""
{
  "targets": [
    {
      "files": [
        {
          "coveredLines": 0,
          "path": "/path/to/file1.swift"
        },
        {
          "coveredLines": 10,
          "path": "/path/to/file2.swift"
        },
        {
          "coveredLines": 20,
          "path": "/path/to/file3.swift"
        }
      ]
    }
  ]
}
"""
