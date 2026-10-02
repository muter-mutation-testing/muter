import Foundation
@testable import muterCore

class FileManagerSpy: Spy, FileSystemManager {

    private(set) var methodCalls: [String] = []
    private(set) var paths: [String] = []
    private(set) var createsIntermediates: [Bool] = []
    private(set) var searchPathDirectories: [FileManager.SearchPathDirectory] = []
    private(set) var domains: [FileManager.SearchPathDomainMask] = []
    private(set) var copyPaths: [(source: String, dest: String)] = []
    private(set) var contentsAtPath: [String] = []
    private(set) var contentsAtPathSorted: [String] = []
    private(set) var contentsAtPathSortedOrder: [ComparisonResult] = []
    private(set) var contents: Data?

    private var fileContentsQueue: Queue<Data> = .init()
    var fileContentsToReturn: Data? {
        set {
            newValue.map { fileContentsQueue.enqueue($0) }
        }
        get {
            fileContentsQueue.dequeue()
        }
    }

    var delegate: FileManagerDelegate?
    private(set) var delegateDuringCopy: FileManagerDelegate?
    /// Files that "disappear" during `copyItem`: each is reported to the delegate as a
    /// no-such-file error, the way Foundation reports one, and the copy carries on if it
    /// says to proceed.
    var pathsVanishingDuringCopy: [String] = []
    var temporaryDirectory: URL = .init(fileURLWithPath: "")
    var currentDirectoryPathToReturn: String = ""
    var changeCurrentDirectoryPath: [String] = []
    var errorToThrow: Error?
    var subpathsToReturn: [String]?
    var fileExistsToReturn: [Bool] = []
    var contentsAtPathSortedToReturn: [String] = []

    var currentDirectoryPath: String {
        currentDirectoryPathToReturn
    }

    @discardableResult func changeCurrentDirectoryPath(
        _ path: String
    ) -> Bool {
        methodCalls.append(#function)
        changeCurrentDirectoryPath.append(path)
        return true
    }

    func createDirectory(
        atPath path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        methodCalls.append(#function)
        paths.append(path)
        createsIntermediates.append(createIntermediates)
        if let error = errorToThrow {
            throw error
        }
    }

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [FileAttributeKey: Any]?
    ) -> Bool {
        methodCalls.append(#function)
        paths.append(path)
        contents = data

        return true
    }

    func copyItem(
        atPath srcPath: String,
        toPath dstPath: String
    ) throws {
        methodCalls.append(#function)
        copyPaths.append((source: srcPath, dest: dstPath))
        delegateDuringCopy = delegate
        if let error = errorToThrow {
            throw error
        }
        for path in pathsVanishingDuringCopy {
            let vanished = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))
            let proceed = delegate?.fileManager?(
                .default, shouldProceedAfterError: vanished, copyingItemAtPath: path, toPath: dstPath
            ) ?? false
            if !proceed {
                throw vanished
            }
        }
    }

    func contents(
        atPath path: String
    ) -> Data? {
        contentsAtPath.append(path)
        methodCalls.append(#function)
        return fileContentsToReturn
    }

    func subpaths(
        atPath path: String
    ) -> [String]? {
        methodCalls.append(#function)
        return subpathsToReturn
    }

    func fileExists(
        atPath path: String
    ) -> Bool {
        methodCalls.append(#function)
        return fileExistsToReturn.isEmpty ? false : fileExistsToReturn.removeFirst()
    }

    func removeItem(
        atPath path: String
    ) throws {
        methodCalls.append(#function)
        paths.append(path)
        if let error = errorToThrow {
            throw error
        }
    }

    func contents(
        atPath path: String,
        sortedByDate: ComparisonResult
    ) throws -> [String] {
        methodCalls.append(#function)
        contentsAtPathSorted.append(path)
        contentsAtPathSortedOrder.append(sortedByDate)
        return contentsAtPathSortedToReturn
    }
}
