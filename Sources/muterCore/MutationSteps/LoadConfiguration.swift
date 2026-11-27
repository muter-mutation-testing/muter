import Foundation

struct LoadConfiguration: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.process)
    private var process: ProcessFactory

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        let configurationPath = configurationPath(state.runOptions)
        do {
            let hasJSON = hasJsonInProjectAtPath(configurationPath)
            let hasYAML = hasYamlInProjectAtPath(configurationPath)
            // A YAML file wins over a legacy JSON file beside it, which migrating would overwrite.
            let isLegacy = hasJSON && !hasYAML

            guard hasYAML || isLegacy,
                  let configurationData = loadConfigurationDataAtPath(
                      configurationPath,
                      legacy: isLegacy
                  )
            else {
                throw MuterError.configurationParsingError(
                    reason: "Could not find \(MuterConfiguration.fileName) at path \(configurationPath)"
                )
            }

            let configuration = try MuterConfiguration(from: configurationData)

            if isLegacy {
                try migrateToYAMLAtPath(configurationPath, configurationData)
            }

            guard isConfigurationValid(configuration) else {
                throw MuterError.configurationParsingError(
                    reason: "Please provide a valid `-destination` argument for your project"
                )
            }

            return [
                .projectDirectoryUrlDiscovered(URL(fileURLWithPath: fileManager.currentDirectoryPath)),
                .configurationParsed(try withResolvedExecutable(configuration)),
            ]
        } catch let error as MuterError {
            throw error
        } catch {
            throw MuterError.configurationParsingError(reason: "\(error)")
        }
    }

    /// Turns a bare command name in `executable` into the absolute path it resolves to on `PATH`.
    ///
    /// A name with no path separator — `swift`, `xcodebuild` — only means anything to a shell, which
    /// searches `PATH` for it. Muter spawns the test command with `Process`, and `Process.executableURL`
    /// resolves a name that isn't an absolute path against the *current working directory*. Later steps
    /// run from the mutated copy of the project, where no such file exists, so the test process fails to
    /// spawn before it can emit a single line. Resolving here — while the working directory is still the
    /// project root — gives every later step an executable it can actually launch.
    private func withResolvedExecutable(
        _ configuration: MuterConfiguration
    ) throws -> MuterConfiguration {
        let executable = configuration.testCommandExecutable
        guard !executable.contains("/") else {
            return configuration
        }

        // Reported verbatim rather than as a `configurationParsingError`: the file parsed fine, so framing
        // this as a parsing or FileManager problem would send the user looking in the wrong place.
        guard let resolved = process().which(executable) else {
            throw MuterError.literal(
                reason: """
                Muter could not find "\(executable)" on your PATH.

                The "executable" option in \(MuterConfiguration.fileNameWithExtension) must name a command \
                that exists on your PATH, or be an absolute path such as "/usr/bin/\(executable)".
                """
            )
        }

        return configuration.withExecutable(resolved)
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
        _ path: String,
        legacy: Bool
    ) -> Data? {
        fileManager.contents(
            atPath: legacy
                ? "\(path.pathWithoutFileName)/\(MuterConfiguration.legacyFileNameWithExtension)"
                : path
        )
    }

    private func migrateToYAMLAtPath(
        _ path: String,
        _ configurationData: Data
    ) throws {
        let configuration = try JSONDecoder().decode(MuterConfiguration.self, from: configurationData)

        // Write the YAML file first, so the settings are not lost if that fails.
        let wrote = fileManager.createFile(
            atPath: "\(path.pathWithoutFileName)/\(MuterConfiguration.fileNameWithExtension)",
            contents: configuration.asData,
            attributes: nil
        )
        guard wrote else { return }

        try fileManager
            .removeItem(atPath: "\(path.pathWithoutFileName)/\(MuterConfiguration.legacyFileNameWithExtension)")
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
