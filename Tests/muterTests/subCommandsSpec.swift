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
                    let runSpy = { runClosureWasCalled = true }

                    let (exitCode, message) = handle(commandlineArguments: ["muter", "notARealSubcommand"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beFalse())
                    expect(runClosureWasCalled).to(beFalse())
                    expect(exitCode).to(equal(1))
                    expect(message).to(contain("Unrecognized subcommand given to Muter\nAvailable subcommands:\n\n\tinit"))
                }
            }

            describe("with the init subcommand") {
                it("runs the setup process") {
                    var setupClosureWasCalled = false
                    let setupSpy = { setupClosureWasCalled = true }

                    var runClosureWasCalled = false
                    let runSpy = { runClosureWasCalled = true }

                    let (exitCode, message) = handle(commandlineArguments: ["muter", "init"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beTrue())
                    expect(runClosureWasCalled).to(beFalse())
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
                    let runSpy = { runClosureWasCalled = true }

                    let (exitCode, message) = handle(commandlineArguments: ["muter", "init"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beTrue())
                    expect(runClosureWasCalled).to(beFalse())
                    expect(exitCode).to(equal(1))
                    expect(message).to(contain("Error creating muter config file"))
                }
            }

            describe("with fewer than 2 commandline arguments") {
                it("runs Muter and returns an exit code of 0 on success") {
                    var setupClosureWasCalled = false
                    let setupSpy = { setupClosureWasCalled = true }

                    var runClosureWasCalled = false
                    let runSpy = { runClosureWasCalled = true }

                    let (exitCode, message) = handle(commandlineArguments: [], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beFalse())
                    expect(runClosureWasCalled).to(beTrue())
                    expect(exitCode).to(equal(0))
                    expect(message).to(beNil())
                }

                it("runs Muter and returns a nonzero exit code when there's a failure ") {
                    var setupClosureWasCalled = false
                    let setupSpy = { setupClosureWasCalled = true }

                    var runClosureWasCalled = false
                    let runSpy = {
                        runClosureWasCalled = true
                        throw TestError.generic
                    }

                    let (exitCode, message) = handle(commandlineArguments: ["muter"], setup: setupSpy, run: runSpy)

                    expect(setupClosureWasCalled).to(beFalse())
                    expect(runClosureWasCalled).to(beTrue())
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

        describe("run()") {
            describe("Temp directory") {
                it("creates a temp directory to store a copy of the code under test") {
                    let configuration = MuterConfiguration.fromFixture(at: "\(self.fixturesDirectory)/muter.conf.withoutBlacklist.json")!
                    let fileManager = FileManagerSpy()
                    fileManager.tempDirectory = URL(fileURLWithPath: "/this/is/a/fake/temp")
                    waitUntil { done in
                        muterCore.run(with: configuration, fileManager: fileManager, in: "/some/test", performMutationTesting: { (currentDirectoryPath, actualConfiguration) in
                            expect(currentDirectoryPath).to(equal("/this/is/a/fake/temp/test"))
                            expect(actualConfiguration).to(equal(configuration))
                            expect(fileManager.searchPathDirectories).to(equal([.itemReplacementDirectory]))
                            expect(fileManager.domains).to(equal([.userDomainMask]))
                            expect(fileManager.paths).to(equal(["/some/test"]))
                            done()
                        })
                    }
                }
            }

            describe("Copying files") {
                it("copies the project to the temp directory before running tests") {
                    let configuration = MuterConfiguration.fromFixture(at: "\(self.fixturesDirectory)/muter.conf.withoutBlacklist.json")!
                    let fileManager = FileManagerSpy()
                    fileManager.tempDirectory = URL(fileURLWithPath: "/this/is/a/fake/temp")
                    waitUntil { done in
                        muterCore.run(with: configuration, fileManager: fileManager, in: "/some/test", performMutationTesting: { (_, _) in
                            expect(fileManager.copyPaths.first?.source).to(equal("/some/test"))
                            expect(fileManager.copyPaths.first?.dest).to(equal("/this/is/a/fake/temp/test"))
                            expect(fileManager.copyPaths).to(haveCount(1))
                            done()
                        })
                    }
                }
            }
        }

        describe("FileManager behaves as we expect it") {
            it("names temporary files predictably") {
                let volumeRoot = URL(fileURLWithPath: "/")
                do {
                    let temporaryDirectory = try FileManager.default.url(
                        for: .itemReplacementDirectory,
                        in: .userDomainMask,
                        appropriateFor: volumeRoot,
                        create: true
                    )
                    expect(temporaryDirectory.absoluteString).to(contain("/var/folders"))
                    expect(temporaryDirectory.absoluteString).to(contain("/T/TemporaryItems/"))
                } catch {
                    fail("Expected no errors, but got \(error)")
                }

            }
        }
    }
}
