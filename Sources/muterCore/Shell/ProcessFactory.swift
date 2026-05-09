import Foundation

let isMuterRunningKey = "IS_MUTER_RUNNING"
let isMuterRunningValue = "YES"

enum MuterProcessFactory {
    /// macOS system tool directories that SwiftPM, xcodebuild, and the
    /// Swift toolchain rely on for helpers like `unzip` (binary-target
    /// extraction), `git` (dependency resolution), `xcrun`, and
    /// `codesign`. They live on the parent shell's PATH for any normal
    /// developer setup, but spawning a Process from a sanitized launchd
    /// or LaunchAgent context can drop them. We re-prepend any that are
    /// missing so SwiftPM never loses access to system tools when muter
    /// runs the test command in the sandbox.
    private static let requiredSystemPathDirectories: [String] = [
        "/usr/bin",
        "/bin",
        "/usr/sbin",
        "/sbin",
    ]

    static func makeProcess() -> MuterProcess {
        let process = Foundation.Process()
        process.qualityOfService = .userInteractive

        var environment = ProcessInfo.processInfo.environment
        environment[isMuterRunningKey] = isMuterRunningValue
        environment["PATH"] = ensureRequiredSystemPaths(in: environment["PATH"])
        process.environment = environment

        return process
    }

    private static func ensureRequiredSystemPaths(in existing: String?) -> String {
        let separator = ":"
        let existingComponents = (existing ?? "")
            .split(separator: Character(separator))
            .map(String.init)
        let existingSet = Set(existingComponents)
        let missing = requiredSystemPathDirectories.filter { !existingSet.contains($0) }
        guard !missing.isEmpty else {
            return existing ?? requiredSystemPathDirectories.joined(separator: separator)
        }
        return (missing + existingComponents).joined(separator: separator)
    }
}
