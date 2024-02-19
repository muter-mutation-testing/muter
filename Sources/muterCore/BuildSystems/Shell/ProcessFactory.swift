import Foundation

let isMuterRunningKey = "IS_MUTER_RUNNING"
let isMuterRunningValue = "YES"

enum MuterProcessFactory {
    static func makeProcess() -> MuterProcess {
        let process = Foundation.Process()
        process.qualityOfService = .userInitiated

        var environment = ProcessInfo.processInfo.environment
        environment[isMuterRunningKey] = isMuterRunningValue
        process.environment = environment

        return process
    }
}
