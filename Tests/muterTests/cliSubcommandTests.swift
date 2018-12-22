import muterCore
import XCTest

@available(OSX 10.13, *)
final class cliSubcommandTests: XCTestCase {
    private enum TestError: Error {
        case generic
    }

    override func tearDown() {
        let workingDirectory = self.testDirectory
        try? FileManager.default.removeItem(atPath: "\(workingDirectory)/muter.conf.json")
    }

    func test_initSubcommandCreatesConfigurationFile() {
        let workingDirectory = self.testDirectory

        try! setupMuter(using: FileManager.default, and: workingDirectory)
        
        guard let contents = FileManager.default.contents(atPath: "\(workingDirectory)/muter.conf.json"),
            let _ = try? JSONDecoder().decode(MuterConfiguration.self, from: contents) else {
              
                XCTFail("Expected a valid configuration file to be written")
                return
        }
    }

    func test_lessThanTwoCommandlineArgumentsRunsMuter() {
        var setupClosureWasCalled = false
        let setupSpy = { setupClosureWasCalled = true }

        var runClosureWasCalled = false
        let runSpy = { runClosureWasCalled = true }

        let (exitCode, message) = handle(commandlineArguments: [], setup: setupSpy, run: runSpy)
        
        XCTAssertFalse(setupClosureWasCalled)
        XCTAssert(runClosureWasCalled)
        XCTAssertEqual(exitCode, 0)
        XCTAssertNil(message)

    }

    func test_passingInitAsACommandlineArgumentsRunsTheSetUpProcess() {
        var setupClosureWasCalled = false
        let setupSpy = { setupClosureWasCalled = true }

        var runClosureWasCalled = false
        let runSpy = { runClosureWasCalled = true }

        let (exitCode, message) = handle(commandlineArguments: ["muter", "init"], setup: setupSpy, run: runSpy)
        
        XCTAssert(setupClosureWasCalled)
        XCTAssertFalse(runClosureWasCalled)
        XCTAssertEqual(exitCode, 0)
        XCTAssert((message ?? "").contains("Created muter config file"))
    }

    func test_setUpFailuresReturnANonzeroExitCode() {
        var setupClosureWasCalled = false
        let setupSpy = { 
            setupClosureWasCalled = true
            throw TestError.generic 
        }

        var runClosureWasCalled = false
        let runSpy = { runClosureWasCalled = true }

        let (exitCode, message) = handle(commandlineArguments: ["muter", "init"], setup: setupSpy, run: runSpy)
        
        XCTAssert(setupClosureWasCalled)
        XCTAssertFalse(runClosureWasCalled)
        XCTAssertEqual(exitCode, 1)
        XCTAssert((message ?? "").contains("Error creating muter config file"))
    }

    func test_runningFailuresReturnANonzeroExitCode() {
        var setupClosureWasCalled = false
        let setupSpy = { setupClosureWasCalled = true }

        var runClosureWasCalled = false
        let runSpy = { 
            runClosureWasCalled = true 
            throw TestError.generic
        }

        let (exitCode, message) = handle(commandlineArguments: ["muter"], setup: setupSpy, run: runSpy)
        
        XCTAssertFalse(setupClosureWasCalled)
        XCTAssert(runClosureWasCalled)
        XCTAssertEqual(exitCode, 1)
        XCTAssert((message ?? "").contains("Error running Muter - make sure your config file exists and is filled out correctly"))
    }

    func test_unrecognizedSubCommandsReturnANonzeroExitCode() {
        var setupClosureWasCalled = false
        let setupSpy = { setupClosureWasCalled = true }

        var runClosureWasCalled = false
        let runSpy = { runClosureWasCalled = true }

        let (exitCode, message) = handle(commandlineArguments: ["muter", "notARealSubcommand"], setup: setupSpy, run: runSpy)
        
        XCTAssertFalse(setupClosureWasCalled)
        XCTAssertFalse(runClosureWasCalled)
        XCTAssertEqual(exitCode, 1)
        XCTAssert((message ?? "").contains("Unrecognized subcommand given to Muter\nAvailable subcommands:\n\n\tinit"))
    }
}
