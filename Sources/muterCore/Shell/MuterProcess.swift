import Foundation

typealias Process = MuterProcess

protocol MuterProcess: AnyObject {
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
}

extension MuterProcess {
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
