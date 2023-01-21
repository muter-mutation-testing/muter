import Foundation

struct BuildForTesting: RunCommandStep {
    private let makeProcess: () -> Launchable

    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter

    init(
        process: @autoclosure @escaping () -> Launchable = Process(),
        fileManager: FileSystemManager = FileManager.default,
        notificationCenter: NotificationCenter = .default
    ) {
        self.makeProcess = process
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
    }

    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        guard state.muterConfiguration.testCommandExecutable.contains("xcodebuild") else {
            return .success([])
        }

        do {
            let buildForTestingOutput = try runBuildForTestingCommand(state.muterConfiguration)
            let buildRequestJsonPath = try findBuildRequestJsonPath(buildForTestingOutput)
            let buildRequest = try parseBuildRequest(buildRequestJsonPath)
            let tempDebugURL = debugURLForTempDirectory(state.tempDirectoryURL)

            try copyBuildArtifactsAtPath(buildRequest.buildProductsPath, to: tempDebugURL.path)

            let xcTestRun = try parseXCTestRunAt(tempDebugURL)

            return .success([
                .projectXCTestRun(xcTestRun)
            ])
        } catch {
            return .failure(
                .literal(reason: "\(error)")
            )
        }
    }

    private func runBuildForTestingCommand(
        _ configuration: MuterConfiguration
    ) throws -> String {
        guard let output: String = runProcess(
            makeProcess,
            url: configuration.testCommandExecutable,
            arguments: configuration.testCommandArguments.dropLast() + ["build-for-testing"]
        ).flatMap(\.nilIfEmpty) else {
            throw MuterError.literal(reason: "Could not run test with -build-for-testing argument")
        }

        return output
    }

    private func findBuildRequestJsonPath(_ output: String) throws -> String {
        guard let buildRequestJsonPath = output.firstMatchOf("Build description path: .*(\\n)")?
            .replacingOccurrences(of: "Build description path: ", with: "")
            .trimmed
            .replacingOccurrences(of: "desc.xcbuild", with: "buildRequest.json") else {
            throw MuterError.literal(reason: "Could not parse buildRequest.json from build description path")
        }

        return buildRequestJsonPath
    }

    private func parseBuildRequest(_ path: String) throws -> XCTestBuildRequest {
        guard let jsonContent = fileManager.contents(atPath: path) else {
            throw MuterError.literal(reason: "Could not parse build request json at path: \(path)")
        }

        return try JSONDecoder().decode(XCTestBuildRequest.self, from: jsonContent)
    }

    private func copyBuildArtifactsAtPath(_ buildPath: String, to destination: String) throws {
        try fileManager.removeItem(
            atPath: destination
        )

        try fileManager.copyItem(
            atPath: buildPath,
            toPath: destination
        )
    }

    private func parseXCTestRunAt(_ url: URL) throws -> XCTestRun {
        let xcTestRunPath = try findMostRecentXCTestRunAtURL(url)
        guard let contents = fileManager.contents(atPath: xcTestRunPath) else {
            throw MuterError.literal(reason: "Could not parse xctestrun at path: \(xcTestRunPath)")
        }

        guard let plist = try PropertyListSerialization.propertyList(from: contents, format: nil) as? [String: AnyHashable] else {
            throw MuterError.literal(reason: "Could not parse xctestrun as plist at path: \(xcTestRunPath)")
        }

        return XCTestRun(plist)
    }

    private func findMostRecentXCTestRunAtURL(_ url: URL) throws -> String {
        guard let xctestrun = try fileManager.contents(
            atPath: url.path,
            sortedByDate: .orderedDescending
        ).first(where: { $0.hasSuffix(".xctestrun") }) else {
            throw MuterError.literal(reason: "Could not find xctestrun file at path: \(url.path)")
        }

        return xctestrun
    }

    private func debugURLForTempDirectory(_ tempURL: URL) -> URL {
        tempURL.appendingPathComponent("Debug")
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

// TODO: Move

struct XCTestRun: Equatable {
    private let plist: [String: AnyHashable]

    init(_ plist: [String: AnyHashable] = [:]) {
        self.plist = plist
    }

    func updateEnvironmentVariable(
        setting setKey: String,
        unsetting unsetKey: String
    ) -> [String: AnyHashable] {
        var copy = plist
        for (plistEntry, plistValue) in copy {
            if var testConfiguration = plistValue as? [String: AnyHashable],
               testConfiguration.keys.contains("EnvironmentVariables"),
               var allEnvironmentVariables = testConfiguration["EnvironmentVariables"] as? [String: AnyHashable] {
                allEnvironmentVariables[setKey] = "YES"
                allEnvironmentVariables[unsetKey] = nil

                testConfiguration["EnvironmentVariables"] = allEnvironmentVariables

                copy[plistEntry] = testConfiguration
            }
        }

        return copy
    }
}
