import Foundation

protocol Launchable: AnyObject {
    var executableURL: URL? { get set }
    var arguments: [String]? { get set }
    var standardOutput: Any? { get set }
    var availableData: Data? { get }
    
    func run() throws
    func waitUntilExit()
}

extension Process: Launchable {
    var availableData: Data? {
        var data = Data()
        while isRunning {
            (standardOutput as? Pipe).flatMap {
                data += $0.fileHandleForReading.availableData
            }
        }
        
        return data
    }
}

func runProcess(
    _ makeProcess: () -> Launchable,
    url: String,
    arguments: [String]
) -> Data? {
    let process = makeProcess()
    process.standardOutput = Pipe()
    process.executableURL = URL(fileURLWithPath: url)
    process.arguments = arguments

    try? process.run()

    let output = process.availableData

    process.waitUntilExit()

    return output
}

func runProcess(
    _ makeProcess: () -> Launchable,
    url: String,
    arguments: [String]
) -> String? {
    guard let output: Data = runProcess(makeProcess, url: url, arguments: arguments) else {
        return nil
    }

    return String(data: output, encoding: .utf8)
}
