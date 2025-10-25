import Foundation

extension MuterConfiguration {
    private static let generators = [
        generateXcodeProjectConfiguration,
        generateXcodeWorkspaceConfiguration,
        generateSPMConfiguration,
        generateEmptyConfiguration
    ]

    init(from directoryContents: [FilePath]) {
        let directoryContents = directoryContents.map(URL.init(fileURLWithPath:))
        let generatedConfiguration = MuterConfiguration
            .generators
            .compactMap { $0(directoryContents) }
            .first!

        self = generatedConfiguration
    }
}

private extension MuterConfiguration {
    static func generateXcodeProjectConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        guard !directoryContainsXcodeWorkspace(directoryContents),
              let index = directoryContents.firstIndex(where: { $0.lastPathComponent.contains(".xcodeproj") }),
              let arguments = arguments(forProjectFileAt: directoryContents[index], isWorkSpace: false)
        else {
            return nil
        }

        return MuterConfiguration(
            executable: executablePath("xcodebuild"),
            arguments: arguments
        )
    }

    static func generateXcodeWorkspaceConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        guard directoryContainsXcodeWorkspace(directoryContents),
              let index = directoryContents.firstIndex(where: { $0.lastPathComponent.contains(".xcodeproj") }),
              let arguments = arguments(forProjectFileAt: directoryContents[index], isWorkSpace: true)
        else {
            return nil
        }

        return MuterConfiguration(
            executable: executablePath("xcodebuild"),
            arguments: arguments
        )
    }

    static func directoryContainsXcodeWorkspace(_ directoryContents: [URL]) -> Bool {
        let indexOfUserGeneratedWorkSpace = directoryContents
            .exclude { $0.absoluteString.contains("project.xcworkspace") }
            .firstIndex { $0.lastPathComponent.contains(".xcworkspace") }

        return indexOfUserGeneratedWorkSpace != nil
    }

    static func arguments(
        forProjectFileAt url: URL,
        isWorkSpace: Bool
    ) -> [String]? {
        guard let projectFile = try? String(
            contentsOf: url.appendingPathComponent("project.pbxproj"),
            encoding: .utf8
        ),
            let projectName = url.lastPathComponent.split(separator: ".").first
        else {
            return nil
        }

        let defaultArguments = [
            isWorkSpace ? "-workspace" : "-project",
            isWorkSpace ? "\(projectName).xcworkspace" : "\(projectName).xcodeproj",
            "-scheme",
            "\(projectName)"
        ]

        let destination = projectFile.contains("SDKROOT = iphoneos") ?
            ["-destination", "platform=iOS Simulator,name=\(iosDestination())"] :
            ["-destination", macOSDestionation(defaultArguments)]

        return defaultArguments + destination + ["test"]
    }

    private static func executablePath(_ exec: String) -> String {
        current.process().which(exec) ?? ""
    }
}

private extension MuterConfiguration {
    static func generateSPMConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        if directoryContents.contains(where: { $0.lastPathComponent == "Package.swift" }) {
            return MuterConfiguration(
                executable: executablePath("swift"),
                arguments: ["test"],
                excludeList: swiftPackageManifestFiles(from: directoryContents)
            )
        }

        return nil
    }

    private static func swiftPackageManifestFiles(from directoryContents: [URL]) -> [String] {
        directoryContents
            .include { $0.lastPathComponent.matches("Package@*.swift") }
            .map(\.lastPathComponent)
    }

    static func generateEmptyConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        MuterConfiguration(executable: "", arguments: [], excludeList: [])
    }
}

private extension MuterConfiguration {
    private struct Simulator: Codable, CustomStringConvertible {
        let isAvailable: Bool
        let name: String
        let deviceTypeIdentifier: String

        var description: String { name }

        static var fallback: Simulator {
            Simulator(
                isAvailable: true,
                name: "iPhone SE (3rd generation)",
                deviceTypeIdentifier: ""
            )
        }
    }

    private static func iosDestination() -> String {
        let process = current.process()
        guard let simulatorsListOutput: Data = process.runProcess(
            url: "/usr/bin/xcrun",
            arguments: ["simctl", "list", "--json"]
        )
        else {
            return Simulator.fallback.name
        }

        do {
            let simulatorsJson = try (
                JSONSerialization
                    .jsonObject(with: simulatorsListOutput) as? [String: AnyHashable]
            ) ??
                [:]
            let devices = (simulatorsJson["devices"] as? [String: AnyHashable]) ?? [:]
            let newestRuntime = devices.keys.filter { $0.contains("iOS") }.sorted().last ?? ""
            let devicesForRunTime = (devices[newestRuntime] as? [AnyHashable]) ?? []
            let device: Simulator? = try devicesForRunTime
                .compactMap { try JSONSerialization.data(withJSONObject: $0) }
                .compactMap { try JSONDecoder().decode(Simulator.self, from: $0) }
                .filter(\.isAvailable)
                .sorted(by: { $0.deviceTypeIdentifier > $1.deviceTypeIdentifier })
                .first { $0.name.contains("iPhone") }

            return device?.name ?? Simulator.fallback.name
        } catch {
            return Simulator.fallback.name
        }
    }

    private static func macOSDestionation(_ projectArguments: [String]) -> String {
        let process = current.process()
        guard let destinationsOutput: String = process.runProcess(
            url: "/usr/bin/xcodebuild",
            arguments: projectArguments + ["-showdestinations"]
        )
        else {
            return ""
        }

        guard let destination = destinationsOutput.firstMatchOf(#"\{\s*([^}]+)\s*\}"#) else {
            return ""
        }

        return destination
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: ", ", with: ",")
            .trimmed
            .replacingOccurrences(of: ":", with: "=")
    }
}
