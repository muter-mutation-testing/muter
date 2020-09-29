import Foundation

struct LoadConfiguration: RunCommandStep {
    private let fileManager: FileSystemManager = FileManager.default
    private let currentDirectory: String
    
    init(currentDirectory: String = FileManager.default.currentDirectoryPath) {
        self.currentDirectory = currentDirectory
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        do {
            guard let configurationData = fileManager.contents(atPath: currentDirectory + "/muter.conf.json") else {
                return .failure(.configurationParsingError(reason: "File does not exist at path \(currentDirectory)/muter.conf.json"))
            }
            
            let configuration = try JSONDecoder().decode(MuterConfiguration.self, from: configurationData)
            
            return .success([
                .projectDirectoryUrlDiscovered(URL(fileURLWithPath: currentDirectory)),
                .configurationParsed(configuration)
            ])
        } catch {
            return .failure(.configurationParsingError(reason: error.localizedDescription))
        }
    }
}
