//import Quick
//import Nimble
//import Foundation
//import muterCore
//import TestingExtensions
//
//@available(OSX 10.13, *)
//class RunCommandSpec: QuickSpec {
//    override func spec() {
//        describe("RunCommand") {
//            var delegateSpy: RunCommandIODelegateSpy!
//            describe("run") {
//                context("with no flags") {
//                    it("executes testing and emits the report as text afterwards") {
//                        delegateSpy = RunCommandIODelegateSpy()
//                        delegateSpy.configurationToReturn = MuterConfiguration(executable: "not empty",
//                                                                               arguments: ["an argument"],
//                                                                               excludeList: ["and exclude"])
//                        let fileManagerSpy = FileManagerSpy()
//                        fileManagerSpy.currentDirectoryPathToReturn = "/something/another"
//
//                        let command = RunCommand(delegate: delegateSpy,
//                                                 fileManager: fileManagerSpy,
//                                                 notificationCenter: NotificationCenter())
//
//                        let options = RunCommandOptions(shouldOutputJSON: false, shouldOutputXcode: false)
//                        
//                        _ = command.run(options)
//                        
//                        expect(delegateSpy.methodCalls).to(equal([
//                            "loadConfiguration()",
//                            "backupProject(in:)",
//                            "executeTesting(using:)"
//                            ]))
//                        expect(delegateSpy.directories).to(equal(["/something/another"]))
//                        expect(delegateSpy.configurations).to(equal([
//                            MuterConfiguration(executable: "not empty",
//                                               arguments: ["an argument"],
//                                               excludeList: ["and exclude"])
//                            ]))
//                    }
//                }
//                
//                context("with JSON report flag") {
//                    it("executes testing and emits the report as JSON afterwards") {
//                        
//                        delegateSpy = RunCommandIODelegateSpy()
//                        delegateSpy.configurationToReturn = MuterConfiguration(executable: "not empty",
//                                                                               arguments: ["an argument"],
//                                                                               excludeList: ["and exclude"])
//                        let options = RunCommandOptions(shouldOutputJSON: true, shouldOutputXcode: false)
//
//                        let fileManagerSpy = FileManagerSpy()
//                        fileManagerSpy.currentDirectoryPathToReturn = "/something/another"
//
//                        let command = RunCommand(delegate: delegateSpy,
//                                                 fileManager: fileManagerSpy,
//                                                 notificationCenter: NotificationCenter())
//                        
//                        guard case .success = command.run(options) else {
//                            fail("Expected a successful result")
//                            return
//                        }
//                        
//                        expect(delegateSpy.methodCalls).to(equal([
//                            "loadConfiguration()",
//                            "backupProject(in:)",
//                            "executeTesting(using:)"
//                            ]))
//                        expect(delegateSpy.directories).to(equal([
//                            "/something/another"
//                            ]))
//                    }
//                }
//                
//                context("with Xcode report flag") {
//                    it("executes testing and emits the report in xcode's format afterwards") {
//                        
//                        delegateSpy = RunCommandIODelegateSpy()
//                        delegateSpy.configurationToReturn = MuterConfiguration(executable: "not empty",
//                                                                               arguments: ["an argument"],
//                                                                               excludeList: ["and exclude"])
//                        let options = RunCommandOptions(shouldOutputJSON: false, shouldOutputXcode: true)
//
//                        let fileManagerSpy = FileManagerSpy()
//                        fileManagerSpy.currentDirectoryPathToReturn = "/something/another"
//
//                        let command = RunCommand(delegate: delegateSpy,
//                                                 fileManager: fileManagerSpy,
//                                                 notificationCenter: NotificationCenter())
//                        
//                        guard case .success = command.run(options) else {
//                            fail("Expected a successful result")
//                            return
//                        }
//                        
//                        expect(delegateSpy.methodCalls).to(equal([
//                            "loadConfiguration()",
//                            "backupProject(in:)",
//                            "executeTesting(using:)"
//                            ]))
//                        expect(delegateSpy.directories).to(equal([
//                            "/something/another"
//                            ]))
//                    }
//                }
//                
//                context("when there's an invalid configuration file") {
//                    beforeEach {
//                        delegateSpy = RunCommandIODelegateSpy()
//                        delegateSpy.configurationToReturn = nil
//                    }
//                    
//                    it("doesn't execute testing") {
//                        let fileManagerSpy = FileManagerSpy()
//                        fileManagerSpy.currentDirectoryPathToReturn = "/"
//                        
//                        let command = RunCommand(delegate: delegateSpy,
//                                                 fileManager: fileManagerSpy,
//                                                 notificationCenter: NotificationCenter())
//                        let options = RunCommandOptions(shouldOutputJSON: false, shouldOutputXcode: false)
//                        let result = command.run(options)
//                        
//                        guard case .failure(let error) = result else {
//                            fail("Expected a configuration error but got \(String(describing: result))")
//                            return
//                        }
//                        
//                        expect(error).to(equal(.configurationParsingError))
//                        expect(delegateSpy.methodCalls).to(equal([
//                            "loadConfiguration()"
//                            ]))
//                    }
//                }
//            }
//        }
//    }
//}
