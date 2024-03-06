import Foundation

struct LoadConfiguration: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        let configurationPath = configurationPath(state.runOptions)
        do {
            let hasJSON = hasJsonInProjectAtPath(configurationPath)
            let hasYAML = hasYamlInProjectAtPath(configurationPath)
            let canLoadConfiguration = hasJSON || hasYAML

            guard canLoadConfiguration,
                  let configurationData = loadConfigurationDataAtPath(
                      configurationPath,
                      legacy: hasJSON
                  )
            else {
                throw MuterError.configurationParsingError(
                    reason: "Could not find \(MuterConfiguration.fileName) at path \(configurationPath)"
                )
            }

            let configuration = try MuterConfiguration(from: configurationData)

            if hasJSON {
                try migrateToYAMLAtPath(configurationPath, configurationData)
            }

            guard isConfigurationValid(configuration) else {
                throw MuterError.configurationParsingError(
                    reason: "Please provide a valid `-destination` argument for your project"
                )
            }

            return [
                .projectDirectoryUrlDiscovered(URL(fileURLWithPath: fileManager.currentDirectoryPath)),
                .configurationParsed(configuration),
            ]
        } catch {
            throw MuterError.configurationParsingError(reason: error.localizedDescription)
        }
    }

    private func configurationPath(_ options: Run.Options) -> String {
        let currentDirectoryPath = options.configurationURL?.path ?? fileManager.currentDirectoryPath
        if currentDirectoryPath.pathContainsConfigExtension {
            return currentDirectoryPath
        }

        return "\(currentDirectoryPath)/\(MuterConfiguration.fileNameWithExtension)"
    }

    private func hasJsonInProjectAtPath(_ path: String) -> Bool {
        fileManager.fileExists(atPath: "\(path.pathWithoutFileName)/\(MuterConfiguration.legacyFileNameWithExtension)")
    }

    private func hasYamlInProjectAtPath(_ path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    private func isConfigurationValid(_ configuration: MuterConfiguration) -> Bool {
        guard configuration.testCommandExecutable.contains("xcodebuild") else {
            return true
        }

        return configuration.testCommandArguments.contains("-destination")
    }

    private func loadConfigurationDataAtPath(
        _ currentDirectory: String,
        legacy: Bool
    ) -> Data? {
        fileManager.contents(
            atPath: legacy
                ? "/\(MuterConfiguration.legacyFileNameWithExtension)"
                : currentDirectory
        )
    }

    private func migrateToYAMLAtPath(
        _ path: String,
        _ configurationData: Data
    ) throws {
        let configuration = try JSONDecoder().decode(MuterConfiguration.self, from: configurationData)

        try fileManager
            .removeItem(atPath: "\(path.pathWithoutFileName)/\(MuterConfiguration.legacyFileNameWithExtension)")

        _ = fileManager.createFile(
            atPath: "\(path.pathWithoutFileName)/\(MuterConfiguration.fileNameWithExtension)",
            contents: configuration.asData,
            attributes: nil
        )
    }

    private func legacyPath(_ path: String) -> String {
        path
    }
}

private extension String {
    var pathContainsConfigExtension: Bool {
        hasSuffix(MuterConfiguration.extension)
    }

    var pathWithoutFileName: String {
        pathContainsConfigExtension ? NSString(string: self).deletingLastPathComponent : self
    }
}
