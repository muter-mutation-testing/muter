import Foundation

typealias Process = MuterProcess

protocol MuterProcess: AnyObject {
    var processIdentifier: Int32 { get }
    var terminationStatus: Int32 { get }
    var terminationHandler: (@Sendable (Foundation.Process) -> Void)? { get set }
    var environment: [String: String]? { get set }
    var arguments: [String]? { get set }
    var executableURL: URL? { get set }
    var standardOutput: Any? { get set }
    var standardError: Any? { get set }

    func runProcess(
        url: String,
        arguments args: [String]
    ) -> Data?

    func run() throws

    func waitUntilExit()

    func terminate()

    func interrupt()

    /// SIGKILL this process and every transitive descendant (default impl walks `ps`). Declared here
    /// so it dynamically dispatches to conformers/test doubles rather than binding statically.
    func terminateTree()
}

extension MuterProcess {
    /// SIGKILL this process and every transitive descendant. `interrupt()`/`terminate()` signal only
    /// the launched command (`swift test` / `xcodebuild`), not the test-runner grandchildren it spawns
    /// (`swiftpm-testing-helper`, `xctest`); those survive, keep spinning at ~100% CPU, and accumulate
    /// across mutants until they starve the machine. Walk parent→child links via `ps` and kill the
    /// whole tree so a timed-out mutant's test leaves nothing behind.
    func terminateTree() {
        let root = processIdentifier
        guard root > 0 else { return }
        for pid in Self.descendantPIDs(of: root) + [root] {
            kill(pid, SIGKILL)
        }
    }

    /// All transitive child PIDs of `root`, discovered from `ps -eo pid,ppid`.
    private static func descendantPIDs(of root: Int32) -> [Int32] {
        let ps = Foundation.Process()
        ps.executableURL = URL(fileURLWithPath: "/bin/ps")
        ps.arguments = ["-eo", "pid,ppid"]
        let pipe = Pipe()
        ps.standardOutput = pipe
        guard (try? ps.run()) != nil else { return [] }
        ps.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return [] }

        var childrenByParent: [Int32: [Int32]] = [:]
        for line in text.split(separator: "\n").dropFirst() {
            let cols = line.split(whereSeparator: { $0 == " " }).compactMap { Int32($0) }
            guard cols.count == 2 else { continue }
            childrenByParent[cols[1], default: []].append(cols[0])
        }

        var result: [Int32] = []
        var queue = childrenByParent[root] ?? []
        while let pid = queue.first {
            queue.removeFirst()
            result.append(pid)
            queue.append(contentsOf: childrenByParent[pid] ?? [])
        }
        return result
    }

    func runProcess(
        url: String,
        arguments: [String]
    ) -> String? {
        guard let output: Data = runProcess(url: url, arguments: arguments) else {
            return nil
        }

        return String(data: output, encoding: .utf8)
    }

    func find(
        atPath path: String,
        byName name: String
    ) -> String? {
        runProcess(
            url: "/usr/bin/find",
            arguments: [path, "-name", name]
        )
        .flatMap(\.nilIfEmpty)
    }

    func findExecutable(
        atPath path: String,
        byName name: String
    ) -> String? {
        runProcess(
            url: "/usr/bin/find",
            arguments: [path, "-type", "f", "-name", name]
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)
    }

    func which(_ application: String) -> String? {
        runProcess(
            url: "/usr/bin/which",
            arguments: [application]
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)
    }
}
