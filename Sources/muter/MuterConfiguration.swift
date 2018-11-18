struct MuterConfiguration: Codable {
    let projectDirectory: String
    let testCommandArguments: [String]
    let testCommandExecutable: String
    
    enum CodingKeys: String, CodingKey {
        case projectDirectory = "projectDirectory"
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
    }
}
