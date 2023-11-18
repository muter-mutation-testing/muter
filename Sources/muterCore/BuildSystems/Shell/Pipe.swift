import Foundation

protocol Pipeable: AnyObject {
    var fileHandleForReading: FileHandle { get }
}

extension Pipe: Pipeable {}
