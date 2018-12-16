struct MuterConfiguration: Codable {
    let testCommandArguments: [String]
    let testCommandExecutable: String
    let blacklist: [String]
    
    enum CodingKeys: String, CodingKey {
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
        case blacklist = "blacklist"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.testCommandExecutable = try container.decode(String.self, forKey: .testCommandExecutable)
        self.testCommandArguments = try container.decode([String].self, forKey: .testCommandArguments)

        let blacklist = try? container.decode([String].self, forKey: .blacklist)
        self.blacklist = blacklist ?? []
    }
}
