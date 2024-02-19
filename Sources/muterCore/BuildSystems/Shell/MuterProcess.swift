import Foundation

typealias Process = MuterProcess

protocol MuterProcess: AnyObject {
    var terminationStatus: Int32 { get }
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
}
