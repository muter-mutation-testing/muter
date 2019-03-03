@testable import muterCore
import Foundation

class RunCommandIODelegateSpy: Spy, RunCommandIODelegate {
    private(set) var methodCalls: [String] = []
    private(set) var directories: [String] = []
    private(set) var configurations: [MuterConfiguration] = []
    public var configurationToReturn: MuterConfiguration!

    func loadConfiguration() -> MuterConfiguration? {
        methodCalls.append(#function)
        return configurationToReturn
    }

    func backupProject(in directory: String) {
        methodCalls.append(#function)
        directories.append(directory)
    }

    func executeTesting(using configuration: MuterConfiguration) {
        methodCalls.append(#function)
        configurations.append(configuration)
    }
}
