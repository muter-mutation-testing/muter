import Foundation

public protocol FileSystemManager {
    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey : Any]?) throws

    func createFile(atPath path: String,
                    contents data: Data?,
                    attributes attr: [FileAttributeKey : Any]?) -> Bool

    func url(for directory: FileManager.SearchPathDirectory,
             in domain: FileManager.SearchPathDomainMask,
             appropriateFor url: URL?,
             create shouldCreate: Bool) throws -> URL

    func copyItem(atPath srcPath: String,
                  toPath dstPath: String) throws

    var currentDirectoryPath: String { get }

    func contents(atPath path: String) -> Data?
}

extension FileManager: FileSystemManager {}
