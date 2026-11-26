import Foundation

struct BuildForTesting: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.process)
    private var process: ProcessFactory
    
    private let testContentsFolder = "TestContents"

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        guard state.muterConfiguration.buildSystem == .xcodebuild else {
            return []
        }

        let currentDirectoryPath = fileManager.currentDirectoryPath

        defer {
            fileManager.changeCurrentDirectoryPath(currentDirectoryPath)
        }

        fileManager.changeCurrentDirectoryPath(state.mutatedProjectDirectoryURL.path)

        do {
            let buildDirectory = try buildDirectory(state.muterConfiguration)
            try runBuildForTestingCommand(state.muterConfiguration)
            let tempDebugURL = createTestContetsUrl(state.mutatedProjectDirectoryURL)
            try copyBuildArtifactsAtPath(buildDirectory, to: tempDebugURL.path)

            let xcTestRun = try parseXCTestRunAt(tempDebugURL, projectURL: state.mutatedProjectDirectoryURL)

            return [.projectXCTestRun(xcTestRun)]
        } catch {
            throw MuterError.literal(reason: "\(error)")
        }
    }

    private func buildDirectory(_ configuration: MuterConfiguration) throws -> String {
        configuration.derivedDataPath
    }

    private func runBuildForTestingCommand(
        _ configuration: MuterConfiguration
    ) throws {
        let buildProcess = process()
        guard let output: String = buildProcess.runProcess(
            url: configuration.testCommandExecutable,
            arguments: configuration.buildForTestingArguments
        ).flatMap(\.nilIfEmpty)
        else {
            throw MuterError.literal(reason: "Could not run test with -build-for-testing argument")
        }

        // A failed build still prints output, so the output alone does not show success. Without this
        // check, Muter went on and reported only that no .xctestrun file was found.
        guard buildProcess.terminationStatus == 0 else {
            throw MuterError.literal(
                reason: Self.buildForTestingFailure(
                    output: output,
                    exitCode: buildProcess.terminationStatus,
                    command: ([configuration.testCommandExecutable] + configuration.buildForTestingArguments)
                        .joined(separator: " ")
                )
            )
        }
    }

    static func buildForTestingFailure(output: String, exitCode: Int32, command: String) -> String {
        let lines = output.components(separatedBy: .newlines)
        var seen = Set<String>()
        let errors = lines
            .map(\.trimmed)
            .filter { $0.contains("error:") && seen.insert($0).inserted }
        let evidence = errors.isEmpty
            ? lines.suffix(20).joined(separator: "\n")
            : errors.prefix(10).joined(separator: "\n")

        return """
        build-for-testing failed (exit code \(exitCode)), so there is no .xctestrun file to test the mutants with.

        \(evidence)

        Run the same command in the mutated copy of your project to see the full output:
        \(command)
        """
    }

    private func parseBuildRequest(_ path: String) throws -> XCTestBuildRequest {
        guard let jsonContent = fileManager.contents(atPath: path) else {
            throw MuterError.literal(reason: "Could not parse build request json at path: \(path)")
        }

        return try JSONDecoder().decode(XCTestBuildRequest.self, from: jsonContent)
    }

    private func copyBuildArtifactsAtPath(_ buildPath: String, to destination: String) throws {
        try? fileManager.removeItem(
            atPath: destination
        )

        try fileManager.copyItem(
            atPath: buildPath,
            toPath: destination
        )
    }

    private func parseXCTestRunAt(_ url: URL, projectURL: URL) throws -> XCTestRun {
        let xcTestRunPath = try findMostRecentXCTestRunAtURL(url)
        let productsDirectory = Self.productsDirectory(
            ofXCTestRunAt: xcTestRunPath,
            inProjectAt: projectURL
        )
        guard let contents = fileManager.contents(atPath: xcTestRunPath),
              let stringContents = String(data: contents, encoding: .utf8)
        else {
            throw MuterError.literal(reason: "Could not parse xctestrun at path: \(xcTestRunPath)")
        }

        guard let replaced = stringContents.replacingOccurrences(
            of: "__TESTROOT__/",
            with: "__TESTROOT__/\(productsDirectory)"
        ).data(using: .utf8)
        else {
            throw MuterError.literal(reason: "Error error")
        }

        guard let plist = try PropertyListSerialization.propertyList(
            from: replaced,
            format: nil
        ) as? [String: AnyHashable]
        else {
            throw MuterError.literal(reason: "Could not parse xctestrun as plist at path: \(xcTestRunPath)")
        }

        return XCTestRun(plist)
    }

    /// The folder that holds the `.xctestrun` file, relative to the project copy, with a trailing slash.
    /// Muter writes its own copy of the file to the project root, so `__TESTROOT__` must point there.
    /// The folder is taken from where xcodebuild put the file, not from a fixed layout, because the
    /// layout inside DerivedData is not documented and can change between Xcode releases.
    static func productsDirectory(ofXCTestRunAt xcTestRunPath: String, inProjectAt projectURL: URL) -> String {
        let fallback = "TestContents/Build/Products/"
        let directory = URL(fileURLWithPath: xcTestRunPath)
            .deletingLastPathComponent()
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
        let project = projectURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path

        guard directory.hasPrefix(project + "/") else {
            return fallback
        }

        return String(directory.dropFirst(project.count + 1)) + "/"
    }

    private func findMostRecentXCTestRunAtURL(_ url: URL) throws -> String {
        guard let xctestrun = try fileManager.contents(
            atPath: url.path,
            sortedByDate: .orderedDescending
        ).first(where: { $0.hasSuffix(".xctestrun") })
        else {
            throw MuterError.literal(reason: "Could not find xctestrun file at path: \(url.path)")
        }

        return xctestrun
    }

    private func createTestContetsUrl(_ tempURL: URL) -> URL {
        tempURL.appendingPathComponent(testContentsFolder)
    }
}

private struct XCTestBuildRequest: Codable {
    var buildProductsPath: String {
        parameters.arenaInfo.buildProductsPath
    }

    private let parameters: Parameters
}

extension XCTestBuildRequest {
    struct Parameters: Codable {
        let arenaInfo: ArenaInfo
    }
}

extension XCTestBuildRequest.Parameters {
    struct ArenaInfo: Codable {
        let buildProductsPath: String
    }
}
