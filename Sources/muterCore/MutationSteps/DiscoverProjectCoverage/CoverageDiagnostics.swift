import Foundation

/// Reports problems with function coverage. Without function coverage, Muter also mutates code that no
/// test runs, and the mutation score goes down, so the user must know when it is missing.
///
/// Set `MUTER_DEBUG_COVERAGE` in the environment to also print each step's result.
enum CoverageDiagnostics {
    static var isDebugEnabled: Bool {
        ProcessInfo.processInfo.environment["MUTER_DEBUG_COVERAGE"] != nil
    }

    static func warn(_ reason: String) {
        write(
            "⚠️ Muter could not read function coverage, so it also mutates code that no test runs. \(reason)"
        )
    }

    static func debug(_ message: @autoclosure () -> String) {
        guard isDebugEnabled else {
            return
        }

        write("[coverage] \(message())")
    }

    private static func write(_ line: String) {
        FileHandle.standardError.write(Data((line + "\n").utf8))
    }
}
