import Foundation

struct LoadConfiguration: RunCommandStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.fileManager.currentDirectoryPath)
    private var currentDirectory: String

    func run(
        with state: AnyRunCommandState
    ) async throws -> [RunCommandState.Change] {
        do {
            let hasJSON = hasJsonInProject()
            let hasYAML = hasYamlInProject()
            let canLoadConfiguration = hasJSON || hasYAML

            guard canLoadConfiguration,
                  let configurationData = loadConfigurationData(legacy: hasJSON)
            else {
                throw MuterError.configurationParsingError(
                    reason: "Could not find \(MuterConfiguration.fileName) at path \(currentDirectory)"
                )
            }

            let configuration = try MuterConfiguration(from: configurationData)

            if hasJSON {
                try migrateToYAML(configurationData)
            }

            guard isConfigurationValid(configuration) else {
                throw MuterError.configurationParsingError(
                    reason: "Please provide a valid `-destination` argument for your project"
                )
            }

            return [
                .projectDirectoryUrlDiscovered(URL(fileURLWithPath: currentDirectory)),
                .configurationParsed(configuration),
            ]
        } catch {
            throw MuterError.configurationParsingError(reason: error.localizedDescription)
        }
    }

    private func hasJsonInProject() -> Bool {
        fileManager.fileExists(
            atPath: currentDirectory + "/\(MuterConfiguration.legacyFileNameWithExtension)"
        )
    }

    private func hasYamlInProject() -> Bool {
        fileManager.fileExists(
            atPath: currentDirectory + "/\(MuterConfiguration.fileNameWithExtension)"
        )
    }

    private func isConfigurationValid(_ configuration: MuterConfiguration) -> Bool {
        guard configuration.testCommandExecutable.contains("xcodebuild") else {
            return true
        }

        return configuration.testCommandArguments.contains("-destination")
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
