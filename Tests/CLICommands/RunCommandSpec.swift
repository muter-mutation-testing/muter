import Quick
import Nimble
import Foundation
import muterCore
import TestingExtensions

@available(OSX 10.13, *)
class RunCommandSpec: QuickSpec {
    override func spec() {
        describe("RunCommand") {
            var delegateSpy: RunCommandIODelegateSpy!

            context("with no flags") {
                it("executes testing and emits the report as text afterwards") {
                    delegateSpy = RunCommandIODelegateSpy()
                    delegateSpy.configurationToReturn = MuterConfiguration(executable: "not empty",
                                                                           arguments: ["an argument"],
                                                                           excludeList: ["and exclude"])
                    let command = RunCommand(delegate: delegateSpy,
                                             currentDirectory: "/something/another")
                    let options = RunCommandOptions(shouldOutputJSON: false, shouldOutputXcode: false)
                    _ = command.run(options)

                    expect(delegateSpy.methodCalls).to(equal([
                        "loadConfiguration()",
                        "backupProject(in:)",
                        "executeTesting(using:)"
                    ]))
                    expect(delegateSpy.directories).to(equal(["/something/another"]))
                    expect(delegateSpy.configurations).to(equal([
                        MuterConfiguration(executable: "not empty",
                                           arguments: ["an argument"],
                                           excludeList: ["and exclude"])
                    ]))
                }
            }

            context("with JSON report flag") {
                it("executes testing and emits the report as JSON afterwards") {

                    delegateSpy = RunCommandIODelegateSpy()
                    delegateSpy.configurationToReturn = MuterConfiguration(executable: "not empty",
                                                                           arguments: ["an argument"],
                                                                           excludeList: ["and exclude"])
                    delegateSpy.reportToReturn = .dummy
                    let options = RunCommandOptions(shouldOutputJSON: true, shouldOutputXcode: false)
                    let command = RunCommand(delegate: delegateSpy, currentDirectory: "/something/another")

                    guard case .success = command.run(options) else {
                        fail("Expected a successful result")
                        return
                    }
                    expect(delegateSpy.methodCalls).to(equal([
                        "loadConfiguration()",
                        "backupProject(in:)",
                        "executeTesting(using:)"
                    ]))
                    expect(delegateSpy.directories).to(equal([
                        "/something/another"
                    ]))
                }
            }

            context("with Xcode report flag") {
                it("executes testing and emits the report in xcode's format afterwards") {

                    delegateSpy = RunCommandIODelegateSpy()
                    delegateSpy.configurationToReturn = MuterConfiguration(executable: "not empty",
                                                                           arguments: ["an argument"],
                                                                           excludeList: ["and exclude"])
                    delegateSpy.reportToReturn = .dummy
                    let options = RunCommandOptions(shouldOutputJSON: false, shouldOutputXcode: true)
                    let command = RunCommand(delegate: delegateSpy, currentDirectory: "/something/another")

                    guard case .success = command.run(options) else {
                        fail("Expected a successful result")
                        return
                    }
                    expect(delegateSpy.methodCalls).to(equal([
                        "loadConfiguration()",
                        "backupProject(in:)",
                        "executeTesting(using:)"
                        ]))
                    expect(delegateSpy.directories).to(equal([
                        "/something/another"
                        ]))
                }
            }

            context("when there is an invalid configuration file") {
                beforeEach {
                    delegateSpy = RunCommandIODelegateSpy()
                    delegateSpy.configurationToReturn = nil
                }

                it("doesn't execute testing") {
                    let command = RunCommand(delegate: delegateSpy,
                                             currentDirectory: "/something/another")
                    let options = RunCommandOptions(shouldOutputJSON: false, shouldOutputXcode: false)

                    guard case .failure(let error) = command.run(options) else {
                        fail("Expected a failure result")
                        return
                    }

                    expect(error).to(equal(.configurationError))
                    expect(delegateSpy.methodCalls).to(equal([
                        "loadConfiguration()"
                    ]))
                }
            }
        }
    }
}

