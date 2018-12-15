import Foundation

protocol FileSystemManager {
    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey : Any]?) throws
}

extension FileManager: FileSystemManager {}
