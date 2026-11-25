import Foundation

let isMuterRunningKey = "IS_MUTER_RUNNING"
let isMuterRunningValue = "YES"

enum MuterProcessFactory {
    static func makeProcess() -> MuterProcess {
        let process = Foundation.Process()
        process.qualityOfService = .userInteractive

        // Preserve the parent environment (PATH, DEVELOPER_DIR, …). Do NOT set IS_MUTER_RUNNING here:
        // this factory also builds the `build-for-testing` process, and on some projects that extra
        // env var makes xcodebuild skip writing `build-request.json`, breaking BuildForTesting's parse.
        // Nothing reads IS_MUTER_RUNNING at build time; it's set on the test process (and xctestrun)
        // where schemata activation lives — see MutationTestingIODelegate.testProcess.
        process.environment = ProcessInfo.processInfo.environment

        return process
    }
}
