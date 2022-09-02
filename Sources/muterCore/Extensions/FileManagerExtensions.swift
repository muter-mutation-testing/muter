import Foundation

public protocol FileSystemManager {
    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws

    func createFile(atPath path: String,
                    contents data: Data?,
                    attributes attr: [FileAttributeKey: Any]?) -> Bool

    func copyItem(atPath srcPath: String,
                  toPath dstPath: String) throws

    var currentDirectoryPath: String { get }

    func contents(atPath path: String) -> Data?
    
    func subpaths(atPath path: String) -> [String]?
    
    func fileExists(atPath path: String) -> Bool
    
    func removeItem(atPath path: String) throws
}

extension FileManager: FileSystemManager {}
