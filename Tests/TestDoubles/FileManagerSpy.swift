import Foundation
@testable import muterCore

class FileManagerSpy: Spy, FileSystemManager {

    private(set) var methodCalls: [String] = []
    private(set) var paths: [String] = []
    private(set) var createsIntermediates: [Bool] = []
    private(set) var searchPathDirectories: [FileManager.SearchPathDirectory] = []
    private(set) var domains: [FileManager.SearchPathDomainMask] = []
    private(set) var copyPaths: [(source: String, dest: String)] = []

    var fileContentsToReturn: Data!
    var currentDirectoryPathToReturn: String!
    var errorToThrow: Error?
    var subpathsToReturn: [String]?
    var fileExistsToReturn: Bool!

    var currentDirectoryPath: String {
        return currentDirectoryPathToReturn
    }

    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        methodCalls.append(#function)
        paths.append(path)
        createsIntermediates.append(createIntermediates)
        if let error = errorToThrow {
            throw error
        }
    }

    func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool {
        methodCalls.append(#function)
        paths.append(path)

        return true
    }

    func copyItem(atPath srcPath: String,
                  toPath dstPath: String) throws {
        methodCalls.append(#function)
        copyPaths.append((source: srcPath, dest: dstPath))
        if let error = errorToThrow { throw error }
    }

    func contents(atPath path: String) -> Data? {
        methodCalls.append(#function)
        return fileContentsToReturn
    }
    
    func subpaths(atPath path: String) -> [String]? {
        methodCalls.append(#function)
        return subpathsToReturn
    }
    
    func fileExists(atPath path: String) -> Bool {
        methodCalls.append(#function)
        return fileExistsToReturn
    }

    func removeItem(atPath path: String) throws {
        methodCalls.append(#function)
        paths.append(path)
        if let error = errorToThrow { throw error }
    }
}
