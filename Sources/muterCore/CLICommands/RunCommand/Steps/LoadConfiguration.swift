import Foundation

struct LoadConfiguration: RunCommandStep {
    private let fileManager: FileSystemManager
    private let currentDirectory: String
    
    init(
        fileManager: FileSystemManager = FileManager.default,
        currentDirectory: String = FileManager.default.currentDirectoryPath
    ) {
        self.fileManager = fileManager
        self.currentDirectory = currentDirectory
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        do {
            let hasJSON = fileManager.fileExists(
                atPath: currentDirectory + "/\(MuterConfiguration.legacyFileNameWithExtension)"
            )
            
            let hasYAML = fileManager.fileExists(
                atPath: currentDirectory + "/\(MuterConfiguration.fileNameWithExtension)"
            )

            guard hasJSON || hasYAML, let configurationData = loadConfigurationData(legacy: hasJSON) else {
                return .failure(
                    .configurationParsingError(reason: "Could not find \(MuterConfiguration.fileName) at path \(currentDirectory)")
                )
            }

            let configuration = try MuterConfiguration.make(from: configurationData)

            if hasJSON {
                try migrateToYAML(configurationData)
            }
            
            return .success([
                    .projectDirectoryUrlDiscovered(URL(fileURLWithPath: currentDirectory)),
                    .configurationParsed(configuration)
                ])
        } catch {
            return .failure(.configurationParsingError(reason: error.localizedDescription))
        }
    }
    
    private func loadConfigurationData(legacy: Bool) -> Data? {
        var path = currentDirectory
        path += legacy
            ? "/\(MuterConfiguration.legacyFileNameWithExtension)"
            : "/\(MuterConfiguration.fileNameWithExtension)"

        return fileManager.contents(atPath: path)
    }
    
    private func migrateToYAML(_ configurationData: Data) throws {
        let configuration = try JSONDecoder().decode(MuterConfiguration.self, from: configurationData)

        try fileManager.removeItem(atPath: currentDirectory + "/\(MuterConfiguration.legacyFileNameWithExtension)")
        
        _ = fileManager.createFile(
            atPath: "\(currentDirectory)/\(MuterConfiguration.fileNameWithExtension)",
            contents: configuration.asData,
            attributes: nil
        )
    }
}
