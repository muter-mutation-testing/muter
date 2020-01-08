import Foundation

public struct MuterConfiguration: Equatable, Codable {
    let testCommandArguments: [String]
    let testCommandExecutable: String
    /// File exclusion list.
    let excludeList: [String]
    /// Exclusion list of functions for Remove Side Effects.
    let excludeCallList: [String]

    enum CodingKeys: String, CodingKey {
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
        case excludeList = "exclude"
        case excludeCallList = "excludeCalls"
    }

    public init(executable: String = "", arguments: [String] = [], excludeList: [String] = [], excludeCallList: [String] = []) {
        self.testCommandExecutable = executable
        self.testCommandArguments = arguments
        self.excludeList = excludeList
        self.excludeCallList = excludeCallList
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        testCommandExecutable = try container.decode(String.self, forKey: .testCommandExecutable)
        testCommandArguments = try container.decode([String].self, forKey: .testCommandArguments)

        let excludeList = try? container.decode([String].self, forKey: .excludeList)
        self.excludeList = excludeList ?? []

        let excludeCallList = try? container.decode([String].self, forKey: .excludeCallList)
        self.excludeCallList = excludeCallList ?? []
    }
}

@available(OSX 10.13, *)
extension MuterConfiguration {
    var asJSONData: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try! encoder.encode(self)
    }
}
