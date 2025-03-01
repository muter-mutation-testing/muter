import Foundation

public protocol FileSystemManager {
    var currentDirectoryPath: String { get }
    var temporaryDirectory: URL { get }
    var delegate: FileManagerDelegate? { get set }

    func createDirectory(
        atPath path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [FileAttributeKey: Any]?
    ) -> Bool

    func copyItem(
        atPath srcPath: String,
        toPath dstPath: String
    ) throws

    @discardableResult func changeCurrentDirectoryPath(_ path: String) -> Bool

    func contents(atPath path: String) -> Data?

    func subpaths(atPath path: String) -> [String]?

    func fileExists(atPath path: String) -> Bool

    func removeItem(atPath path: String) throws

    func contents(atPath path: String, sortedByDate order: ComparisonResult) throws -> [String]
}

extension FileManager: FileSystemManager {
    public func contents(
        atPath path: String,
        sortedByDate order: ComparisonResult
    ) throws -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        var files = [URL]()
        while let url = enumerator.nextObject() as? URL {
            files.append(url)
        }

        if files.isEmpty {
            return []
        }

        try files.sort {
            let lhs = try $0.resourceValues(forKeys: [URLResourceKey.creationDateKey])
            let rhs = try $1.resourceValues(forKeys: [URLResourceKey.creationDateKey])

            if let lhsDate = lhs.allValues.first?.value as? Date,
               let rhsDate = rhs.allValues.first?.value as? Date {

                return lhsDate.compare(rhsDate) == order
            }
            return true
        }
        return files.map(\.path)
    }
}
