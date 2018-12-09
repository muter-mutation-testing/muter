struct MuterConfiguration: Codable {
    let testCommandArguments: [String]
    let testCommandExecutable: String
    
    enum CodingKeys: String, CodingKey {
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
    }
}
