import muterCore
import Foundation
import Quick
import Nimble

@available(OSX 10.13, *)
class CLISubcommandSpec: QuickSpec {
    private enum TestError: Error {
        case generic
    }

    override func spec() {
        describe("CLI Handling") {
            describe("with any unrecognized subcommands") {
                it("returns a nonzero exit code") {
                    var setupClosureWasCalled = false
                    let setupSpy = { setupClosureWasCalled = true }

                    var runClosureWasCalled = false
                    var flagPassed: CommandFlag = .empty
                    let runSpy: ThrowingCommandFlagClosure = {
                        flagPassed = $0
                        runClosureWasCalled = true
                    }

                    let (exitCode, message) = handle(commandlineArguments: ["muter", "notARealSubcommand"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beFalse())
                    expect(runClosureWasCalled).to(beFalse())
                    expect(flagPassed).to(equal(.empty))
                    expect(exitCode).to(equal(1))
                    expect(message).to(contain("Unrecognized subcommand given to Muter\nAvailable subcommands:\n\n\tinit"))
                }
            }

            describe("with the init subcommand") {
                it("runs the setup process") {
                    var setupClosureWasCalled = false
                    let setupSpy = { setupClosureWasCalled = true }

                    var runClosureWasCalled = false
                    var flagPassed: CommandFlag = .empty
                    let runSpy: ThrowingCommandFlagClosure = {
                        flagPassed = $0
                        runClosureWasCalled = true
                    }

                    let (exitCode, message) = handle(commandlineArguments: ["muter", "init"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beTrue())
                    expect(runClosureWasCalled).to(beFalse())
                    expect(flagPassed).to(equal(.empty))
                    expect(exitCode).to(equal(0))
                    expect(message).to(contain("Created muter config file"))
                }

                it("returns an exit code of 1 when it encounters an error") {
                    var setupClosureWasCalled = false
                    let setupSpy = {
                        setupClosureWasCalled = true
                        throw TestError.generic
                    }

                    var runClosureWasCalled = false
                    var flagPassed: CommandFlag = .empty
                    let runSpy: ThrowingCommandFlagClosure = {
                        flagPassed = $0
                        runClosureWasCalled = true
                    }
                    
                    let (exitCode, message) = handle(commandlineArguments: ["muter", "init"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beTrue())
                    expect(runClosureWasCalled).to(beFalse())
                    expect(flagPassed).to(equal(.empty))
                    expect(exitCode).to(equal(1))
                    expect(message).to(contain("Error creating muter config file"))
                }
            }

            describe("with the json flag") {
                it("runs Muter and returns an exit code of 0 on success") {
                    var setupClosureWasCalled = false
                    let setupSpy = { setupClosureWasCalled = true }

                    var runClosureWasCalled = false
                    var flagPassed: CommandFlag = .empty
                    let runSpy: ThrowingCommandFlagClosure = {
                        flagPassed = $0
                        runClosureWasCalled = true
                    }

                    let (exitCode, message) = handle(commandlineArguments: ["muter", "--output-json"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beFalse())
                    expect(runClosureWasCalled).to(beTrue())
                    expect(flagPassed).to(equal(.jsonOutput))
                    expect(exitCode).to(equal(0))
                    expect(message).to(beNil())
                }
            }

            describe("with fewer than 2 commandline arguments") {
                it("runs Muter and returns an exit code of 0 on success") {
                    var setupClosureWasCalled = false
                    let setupSpy = { setupClosureWasCalled = true }

                    var runClosureWasCalled = false
                    var flagPassed: CommandFlag = .empty
                    let runSpy: ThrowingCommandFlagClosure = {
                        flagPassed = $0
                        runClosureWasCalled = true
                    }

                    let (exitCode, message) = handle(commandlineArguments: [], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beFalse())
                    expect(runClosureWasCalled).to(beTrue())
                    expect(flagPassed).to(equal(.empty))
                    expect(exitCode).to(equal(0))
                    expect(message).to(beNil())
                }

                it("runs Muter and returns a nonzero exit code when there's a failure ") {
                    var setupClosureWasCalled = false
                    let setupSpy = { setupClosureWasCalled = true }

                    var runClosureWasCalled = false
                    var flagPassed: CommandFlag = .empty
                    let runSpy: ThrowingCommandFlagClosure = {
                        flagPassed = $0
                        runClosureWasCalled = true
                        throw TestError.generic
                    }

                    let (exitCode, message) = handle(commandlineArguments: ["muter"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beFalse())
                    expect(runClosureWasCalled).to(beTrue())
                    expect(flagPassed).to(equal(.empty))
                    expect(exitCode).to(equal(1))
                    expect(message).to(contain("Error running Muter - make sure your config file exists and is filled out correctly"))
                }
            }
        }

        describe("Setup handling") {
            afterEach {
                let workingDirectory = self.rootTestDirectory
                try? FileManager.default.removeItem(atPath: "\(workingDirectory)/muter.conf.json")
            }

            it("creates a configuration file named muter.conf.json with placeholder values in a specified directory") {
                let workingDirectory = self.rootTestDirectory

                guard let _ = try? setupMuter(using: FileManager.default, and: workingDirectory),
                    let contents = FileManager.default.contents(atPath: "\(workingDirectory)/muter.conf.json"),
                    let _ = try? JSONDecoder().decode(MuterConfiguration.self, from: contents) else {

                        fail("Expected a valid configuration file to be written")
                        return
                }
            }
        }

        describe("Copying a project into a temporary directory") {
            var fileManagerSpy: FileManagerSpy!
            var temporaryUrl: String!

            beforeEach {
                fileManagerSpy = FileManagerSpy()
                fileManagerSpy.tempDirectory = URL(string: "/tmp/")!
                temporaryUrl = copyProject(in: URL(string: "/some/projectName")!, using: fileManagerSpy)
            }

            it("creates a temp directory to store a copy of the code under test") {
                expect(temporaryUrl).to(equal(URL(string: "/tmp/projectName")!.absoluteString))

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

        describe("Saving mutation test reports") {
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
                let testDirectory = URL(fileURLWithPath: "\(self.rootTestDirectory)")

                save(report, to: testDirectory)

                guard let _ = realFileManager.contents(atPath: "\(self.rootTestDirectory)/muterReport.json") else {
                    fail("Expected a JSON file to be written to \(self.rootTestDirectory)/muterReport.json")
                    return
                }
            }
        }
        
        describe("Running muter") {
            describe("with json report flag") {
                it("should save the report as json") {
                    var copyCalled = false
                    var directoryPassed: URL?
                    var fileManagerPassed: FileSystemManager?
                    let copySpy: (URL, FileSystemManager) -> String = {
                        copyCalled = true
                        directoryPassed = $0
                        fileManagerPassed = $1

                        return "destination path value"
                    }

                    var reporterCalled = false
                    var destinationPathPassed: String?
                    var configurationPassed: MuterConfiguration?
                    let beginMutationTestingSpy: (String, MuterConfiguration) -> MuterTestReport? = {
                        reporterCalled = true
                        destinationPathPassed = $0
                        configurationPassed = $1

                        return .dummy
                    }

                    var saveCalled = false
                    var reportPassed: MuterTestReport?
                    var currentDirectoryPassed: URL?
                    let saveSpy: (MuterTestReport?, URL) -> Void = {
                        saveCalled = true
                        reportPassed = $0
                        currentDirectoryPassed = $1
                    }

                    let path = self.productsDirectory.absoluteString
                    let fileManager = FileManagerSpy()
                    let configuration = MuterConfiguration.fromFixture(at: "\(self.fixturesDirectory)/muter.conf.withoutExcludeList.json")!
                    muterCore.run(
                        with: configuration,
                        flag: .jsonOutput,
                        in: path,
                        fileManager: fileManager,
                        copy: copySpy,
                        beginMutationTesting: beginMutationTestingSpy,
                        save: saveSpy
                    )

                    expect(copyCalled).to(beTrue())
                    expect(directoryPassed).to(equal(URL(fileURLWithPath: path)))
                    expect(fileManagerPassed).to(be(fileManager))
                    expect(reporterCalled).to(beTrue())
                    expect(destinationPathPassed).to(equal("destination path value"))
                    expect(configurationPassed).to(equal(configuration))
                    expect(saveCalled).to(beTrue())
                    expect(reportPassed).to(equal(.dummy))
                    expect(currentDirectoryPassed).to(equal(URL(fileURLWithPath: path)))
                }
            }
            
            describe("without json report flag") {
                it("shouldn't save the report as json") {
                    var copyCalled = false
                    var directoryPassed: URL?
                    var fileManagerPassed: FileSystemManager?
                    let copySpy: (URL, FileSystemManager) -> String = {
                        copyCalled = true
                        directoryPassed = $0
                        fileManagerPassed = $1

                        return "destination path value"
                    }

                    var reporterCalled = false
                    var destinationPathPassed: String?
                    var configurationPassed: MuterConfiguration?
                    let beginMutationTestingSpy: (String, MuterConfiguration) -> MuterTestReport? = {
                        reporterCalled = true
                        destinationPathPassed = $0
                        configurationPassed = $1

                        return .dummy
                    }

                    var saveCalled = false
                    var reportPassed: MuterTestReport?
                    var currentDirectoryPassed: URL?
                    let saveSpy: (MuterTestReport?, URL) -> Void = {
                        saveCalled = true
                        reportPassed = $0
                        currentDirectoryPassed = $1
                    }

                    let path = self.productsDirectory.absoluteString
                    let fileManager = FileManagerSpy()
                    let configuration = MuterConfiguration.fromFixture(at: "\(self.fixturesDirectory)/muter.conf.withoutExcludeList.json")!
                    muterCore.run(
                        with: configuration,
                        flag: .empty,
                        in: path,
                        fileManager: fileManager,
                        copy: copySpy,
                        beginMutationTesting: beginMutationTestingSpy,
                        save: saveSpy
                    )

                    expect(copyCalled).to(beTrue())
                    expect(directoryPassed).to(equal(URL(fileURLWithPath: path)))
                    expect(fileManagerPassed).to(be(fileManager))
                    expect(reporterCalled).to(beTrue())
                    expect(destinationPathPassed).to(equal("destination path value"))
                    expect(configurationPassed).to(equal(configuration))
                    expect(saveCalled).to(beFalse())
                    expect(reportPassed).to(beNil())
                    expect(currentDirectoryPassed).to(beNil())
                }
            }
        }
    }
}

extension MuterTestReport {
    static var dummy: MuterTestReport {
        return .init(from:
            [
                .init(testSuiteOutcome: .failed,
                      appliedMutation: .negateConditionals,
                      filePath: "some path",
                      position: .firstPosition)
            ]
        )
    }
}
