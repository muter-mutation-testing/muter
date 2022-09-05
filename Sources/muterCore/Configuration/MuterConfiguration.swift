import Foundation

public struct MuterConfiguration: Equatable, Codable {
    let testCommandArguments: [String]
    let testCommandExecutable: String
    /// File exclusion list.
    let excludeFileList: [String]
    /// Exclusion list of functions for Remove Side Effects.
    let excludeCallList: [String]
    let mutateFilesInSiblingOfProjectFolder: Bool

    enum CodingKeys: String, CodingKey {
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
        case excludeFileList = "exclude"
        case excludeCallList = "excludeCalls"
        case mutateFilesInSiblingOfProjectFolder = "mutateInSiblingFolder"
    }

    public init(executable: String = "",
                arguments: [String] = [],
                excludeList: [String] = [],
                excludeCallList: [String] = [],
                mutateFilesInSiblingOfProjectFolder: Bool = false) {
        self.testCommandExecutable = executable
        self.testCommandArguments = arguments
        self.excludeFileList = excludeList
        self.excludeCallList = excludeCallList
        self.mutateFilesInSiblingOfProjectFolder = mutateFilesInSiblingOfProjectFolder
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        testCommandExecutable = try container.decode(String.self, forKey: .testCommandExecutable)
        testCommandArguments = try container.decode([String].self, forKey: .testCommandArguments)

        let excludeList = try? container.decode([String].self, forKey: .excludeFileList)
        self.excludeFileList = excludeList ?? []

        let excludeCallList = try? container.decode([String].self, forKey: .excludeCallList)
        self.excludeCallList = excludeCallList ?? []
        
        let mutateFilesInSiblingOfProjectFolder = try? container.decode(Bool.self, forKey: .mutateFilesInSiblingOfProjectFolder)
        self.mutateFilesInSiblingOfProjectFolder = mutateFilesInSiblingOfProjectFolder ?? false
    }
}

extension MuterConfiguration {
    var asJSONData: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try! encoder.encode(self)
    }
}
