import Foundation
@testable import muterCore

class FileManagerSpy: Spy, FileSystemManager {

    private(set) var methodCalls: [String] = []
    private(set) var paths: [String] = []
    private(set) var createsIntermediates: [Bool] = []
    private(set) var searchPathDirectories: [FileManager.SearchPathDirectory] = []
    private(set) var domains: [FileManager.SearchPathDomainMask] = []
    private(set) var copyPaths: [(source: String, dest: String)] = []

    var tempDirectory: URL!
    var fileContentsToReturn: Data!
    var currentDirectoryPathToReturn: String!

    var currentDirectoryPath: String {
        return currentDirectoryPathToReturn
    }

    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        methodCalls.append(#function)
        paths.append(path)
        createsIntermediates.append(createIntermediates)
    }

    func url(for directory: FileManager.SearchPathDirectory,
             in domain: FileManager.SearchPathDomainMask,
             appropriateFor url: URL?,
             create shouldCreate: Bool) throws -> URL {
        methodCalls.append(#function)
        searchPathDirectories.append(directory)
        domains.append(domain)
        if let path = url?.path {
            paths.append(path)
        }
        return tempDirectory
    }

    func copyItem(atPath srcPath: String,
                  toPath dstPath: String) throws {
        methodCalls.append(#function)
        copyPaths.append((source: srcPath, dest: dstPath))
    }

    func contents(atPath path: String) -> Data? {
        methodCalls.append(#function)
        return fileContentsToReturn
    }

}
