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
