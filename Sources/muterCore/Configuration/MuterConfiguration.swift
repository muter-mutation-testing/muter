import Foundation
import Yams

public struct MuterConfiguration: Equatable, Codable {
    let testCommandArguments: [String]
    let testCommandExecutable: String
    /// File exclusion list.
    let excludeFileList: [String]
    /// Exclusion list of functions for Remove Side Effects.
    let excludeCallList: [String]

    enum CodingKeys: String, CodingKey {
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
        case excludeFileList = "exclude"
        case excludeCallList = "excludeCalls"
    }

    public init(
        executable: String = "",
        arguments: [String] = [],
        excludeList: [String] = [],
        excludeCallList: [String] = []
    ) {
        self.testCommandExecutable = executable
        self.testCommandArguments = arguments
        self.excludeFileList = excludeList
        self.excludeCallList = excludeCallList
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        testCommandExecutable = try container.decode(String.self, forKey: .testCommandExecutable)
        testCommandArguments = try container.decode([String].self, forKey: .testCommandArguments)

        let excludeList = try? container.decode([String].self, forKey: .excludeFileList)
        self.excludeFileList = excludeList ?? []

        let excludeCallList = try? container.decode([String].self, forKey: .excludeCallList)
        self.excludeCallList = excludeCallList ?? []
    }
}

extension MuterConfiguration {
    static let fileName = "muter.conf"
    static let fileNameWithExtension = fileName + ".yaml"
    static let legacyFileNameWithExtension = fileName + ".json"
}

extension MuterConfiguration {
    static func make(from data: Data) throws -> Self {
        do {
            return try YAMLDecoder().decode(MuterConfiguration.self, from: data)
        } catch {
            return try JSONDecoder().decode(MuterConfiguration.self, from: data)
        }
    }
}

extension MuterConfiguration {
    var asData: Data {
        let encoder = YAMLEncoder()
        return (try! encoder.encode(self)).data(using: .utf8)!
    }
}
