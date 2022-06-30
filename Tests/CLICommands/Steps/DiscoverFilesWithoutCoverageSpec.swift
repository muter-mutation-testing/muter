import Quick
import Nimble
import Foundation
@testable import muterCore

class DiscoverProjectCoverageSpec: QuickSpec {
    override func spec() {
        describe("the DiscoverProjectCoverage step") {
            var discoverFilesWithoutCoverage: DiscoverProjectCoverage!
            var state: RunCommandState!
            var process: LaunchableSpy!
            
            beforeEach {
                state = RunCommandState()
                process = LaunchableSpy()
                discoverFilesWithoutCoverage = DiscoverProjectCoverage(
                    process: process
                )
            }
            
            describe("when step starts") {
                beforeEach {
                    state.muterConfiguration = MuterConfiguration(
                        executable: "/path/to/xcodebuild",
                        arguments: ["arg0", "arg1"]
                    )
                }

                it("should fire a notification") {
                    expect(
                        { _ = discoverFilesWithoutCoverage.run(with: state)}
                    ).to(
                        postNotifications(
                            beginWith(Notification(name: .projectCoverageDiscoveryStarted, object: nil))
                        )
                    )
                }
            }

            describe("when project uses a supported build system") {
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
                    
                    context("when build succeeds") {
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
                                        .projectCoverage(
                                            Coverage.make(
                                                percent: 81,
                                                filesWithoutCoverage: [
                                                    "/path/to/file1.swift",
                                                ]
                                            )
                                        ),
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
                    
                    context("when build fails") {
                        beforeEach {
                            process.stdoutToBeReturned = ""
                            
                            _ = discoverFilesWithoutCoverage.run(with: state)
                        }
                        
                        it("then dont execute xcode-select command") {
                            expect(process.executableURL?.absoluteString).notTo(equal("file:///usr/bin/xcode-select"))
                        }
                    }
                }
                
                describe("when project uses `swift`") {
                    beforeEach {
                        state.muterConfiguration = MuterConfiguration(
                            executable: "/path/to/swift",
                            arguments: ["arg0", "arg1"]
                        )
                    }
                    
                    it("should run build command with coverage") {
                        _ = discoverFilesWithoutCoverage.run(with: state)
                        
                        expect(process.executableURL?.absoluteString).to(equal("file:///path/to/swift"))
                        expect(process.arguments).to(equal(["arg0", "arg1", "--enable-code-coverage", "--verbose"]))
                        expect(process.runCalled).to(beTrue())
                        expect(process.waitUntilExitCalled).to(beTrue())
                    }
                    
                    context("when build succeeds") {
                        beforeEach {
                            process.stdoutToBeReturned =
                                """
                                Test Suite 'muterPackageTests.xctest' failed at 2021-02-25 16:20:37.112.
                                     Executed 144 tests, with 5 failures (0 unexpected) in 2.109 (2.116) seconds
                                Test Suite 'All tests' failed at 2021-02-25 16:20:37.113.
                                     Executed 144 tests, with 5 failures (0 unexpected) in 2.109 (2.117) seconds
                                /path/to/llvm-profdata merge -sparse /path/to/default16636031009452225957_0.profraw -o /path/to/default.profdata
                                /path/to/llvm-cov export -instr-profile=/path/to/default.profdata /path/to/muterPackageTests
                                """
                            
                            _ = discoverFilesWithoutCoverage.run(with: state)
                        }
                        
                        it("should execute `llvm-cov` command") {
                            expect(process.executableURL?.absoluteString).to(equal("file:///path/to/llvm-cov"))
                            expect(process.arguments).to(equal([
                                "report",
                                "-instr-profile=/path/to/default.profdata",
                                "/path/to/muterPackageTests",
                                "--ignore-filename-regex=.build|Tests",
                            ]))
                        }
                        
                        context("when `llvm-cov` succeeds") {
                            beforeEach {
                                process.stdoutToBeReturned =
                                    """
                                    Test Suite 'muterPackageTests.xctest' failed at 2021-02-25 16:20:37.112.
                                         Executed 144 tests, with 5 failures (0 unexpected) in 2.109 (2.116) seconds
                                    Test Suite 'All tests' failed at 2021-02-25 16:20:37.113.
                                         Executed 144 tests, with 5 failures (0 unexpected) in 2.109 (2.117) seconds
                                    /path/to/llvm-profdata merge -sparse /path/to/default16636031009452225957_0.profraw -o /path/to/default.profdata
                                    /path/to/llvm-cov export -instr-profile=/path/to/default.profdata /path/to/muterPackageTests
                                    """
                                process.stdoutToBeReturned = loadLLVMCovLog()
                            }

                            it("should parse results") {
                                let result = try! discoverFilesWithoutCoverage.run(with: state).get()
                                expect(result).to(equal([
                                    .projectCoverage(
                                        Coverage.make(
                                            percent: 78,
                                            filesWithoutCoverage: [
                                                "CLICommands/MuterError.swift",
                                                "Extensions/Nullable.swift",
                                                "Extensions/ProgressExtensions.swift",
                                                "MutationTesting/MutationTestingAbortReason.swift",
                                                "Muter.swift",
                                            ])
                                    ),
                                ]))
                            }
                        }
                    }
                    
                    context("when build fails") {
                        beforeEach {
                            _ = discoverFilesWithoutCoverage.run(with: state)
                        }
                        
                        it("then dont execute anything") {
                            let result = try? discoverFilesWithoutCoverage.run(with: state).get()
                            expect(result).to(equal([.projectCoverage(.null)]))
                        }
                    }
                }
            }
            
            describe("when project does not use a supported build system") {
                beforeEach {
                    state.muterConfiguration = MuterConfiguration(
                        executable: "/path/to/build-system"
                    )
                }

                it("should return an empty list") {
                    let result = try! discoverFilesWithoutCoverage.run(with: state).get()
                    
                    expect(result).to(haveCount(1))
                    expect(result).to(equal([.projectCoverage(.null)]))
                }
                
                it("should not run build command") {
                    _ = discoverFilesWithoutCoverage.run(with: state)

                    expect(process.runCalled).to(beFalse())
                    expect(process.waitUntilExitCalled).to(beFalse())
                }
            }
            
            describe("when step finishes") {
                context("with success") {
                    beforeEach {
                        state.muterConfiguration = MuterConfiguration(
                            executable: "/path/to/xcodebuild",
                            arguments: ["arg0", "arg1"]
                        )

                        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
                        process.stdoutToBeReturned = "/path/to/xccov"
                        process.stdoutToBeReturned = coverageData
                    }

                    it("should fire a notification") {
                        expect(
                            { _ = discoverFilesWithoutCoverage.run(with: state) }
                        ).to(
                            postNotifications(
                                contain(
                                    Notification(name: .projectCoverageDiscoveryFinished, object: true)
                                )
                            )
                        )
                    }
                }
                
                context("with failure") {
                    beforeEach {
                        state.muterConfiguration = MuterConfiguration(
                            executable: "/path/to/xcodebuild",
                            arguments: ["arg0", "arg1"]
                        )

                        process.stdoutToBeReturned = ""
                    }

                    it("should fire a notification") {
                        expect(
                            { _ = discoverFilesWithoutCoverage.run(with: state) }
                        ).to(
                            postNotifications(
                                contain(
                                    Notification(name: .projectCoverageDiscoveryFinished, object: false)
                                )
                            )
                        )
                    }
                }
            }
        }
    }
}

private func loadLLVMCovLog() -> String {
    guard let data = FileManager.default.contents(atPath: "\(DiscoverProjectCoverageSpec().fixturesDirectory)/logFromllvm-cov.txt"),
          let string = String(data: data, encoding: .utf8) else {
        fatalError("Unable to load reportfor testing")
    }
    
    return string
}
    
private class LaunchableSpy: Launchable {
    var executableURL: URL?
    var arguments: [String]?
    var standardOutput: Any?
    
    var stdoutToBeReturned = "" {
        didSet {
            stdoutToBeReturned
                .data(using: .utf8)
                .map(queue.enqueue)
        }
    }

    private let queue = Queue()
    var availableData: Data? {
        queue.dequeue()
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
      "lineCoverage": 0.81051478641840091,
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
      ],
     "name": "Project.framework"
    },
    {
      "lineCoverage": 0.86051478641840091,
      "files": [
        {
          "coveredLines": 0,
          "path": "/path/to/file4.swift"
        },
        {
          "coveredLines": 10,
          "path": "/path/to/file5.swift"
        },
        {
          "coveredLines": 20,
          "path": "/path/to/file6.swift"
        }
      ],
     "name": "Project-OSXTests.xctest"
    }
  ]
}
"""
