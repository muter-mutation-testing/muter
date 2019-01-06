public struct MuterConfiguration: Codable {
    let testCommandArguments: [String]
    let testCommandExecutable: String
    let blacklist: [String]

    enum CodingKeys: String, CodingKey {
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
        case blacklist
    }

    public init(executable: String, arguments: [String], blacklist: [String]) {
        self.testCommandExecutable = executable
        self.testCommandArguments = arguments
        self.blacklist = blacklist
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        testCommandExecutable = try container.decode(String.self, forKey: .testCommandExecutable)
        testCommandArguments = try container.decode([String].self, forKey: .testCommandArguments)

        let blacklist = try? container.decode([String].self, forKey: .blacklist)
        self.blacklist = blacklist ?? []
    }
}
