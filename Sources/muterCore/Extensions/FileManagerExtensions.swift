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
    /// Every file under `path`, recursively, sorted by modification date. A file without a date sorts as
    /// the oldest. Modification dates survive a copy; creation dates become the time of the copy.
    public func contents(
        atPath path: String,
        sortedByDate order: ComparisonResult
    ) throws -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files = [(path: String, date: Date)]()
        while let url = enumerator.nextObject() as? URL {
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            files.append((url.path, date))
        }

        switch order {
        case .orderedDescending:
            files.sort { $0.date > $1.date }
        case .orderedAscending:
            files.sort { $0.date < $1.date }
        case .orderedSame:
            break
        }

        return files.map(\.path)
    }
}
