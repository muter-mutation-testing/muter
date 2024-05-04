import Foundation

extension MuterConfiguration {
    private static let generators = [
        generateXcodeProjectConfiguration,
        generateXcodeWorkspaceConfiguration,
        generateSPMConfiguration,
        generateEmptyConfiguration,
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
            "\(projectName)",
        ]

        let destination = projectFile.contains("SDKROOT = iphoneos") ?
            ["-destination", "platform=iOS Simulator,name=\(iOSSimulator().name)"] :
            []

        return defaultArguments + destination + ["test"]
    }

    private static func executablePath(_ exec: String) -> String {
        current.process().which(exec) ?? ""
    }
}

private extension MuterConfiguration {
    static func generateSPMConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        guard directoryContents.contains(where: { $0.lastPathComponent == "Package.swift" }) else {
            return nil
        }

        let swiftExecutable = executablePath("swift")

        lazy var defaultSPMConfiguration: MuterConfiguration = MuterConfiguration(
            executable: swiftExecutable,
            arguments: ["test"],
            excludeList: swiftPackageManifestFiles(from: directoryContents)
        )

        guard let swiftDumpPackage = swiftDumpPackage(swiftExecutable: swiftExecutable) else {
            return defaultSPMConfiguration
        }

        let platformsIncludeiOS = swiftDumpPackage.platforms.contains(where: {
            $0.platformName.lowercased() == "ios"
        })

        guard platformsIncludeiOS else {
            return defaultSPMConfiguration
        }

        let xcodeBuildExecutable = executablePath("xcodebuild")
        // If an SPM library has more than 1 product a "-Package" scheme is generated automatically.
        let predictedPackageScheme = "\(swiftDumpPackage.name)-Package"
        let fallbackScheme = swiftDumpPackage.name
        let schemes = swiftPackageSchemes(xcodebuildExecutable: xcodeBuildExecutable)
        let candidateSchemes: [() -> String?] = [
            { schemes.first { $0 == predictedPackageScheme } },
            { schemes.first { $0.contains(swiftDumpPackage.name) } },
            { schemes.first },
        ]
        let scheme = candidateSchemes.lazy.compactMap { $0() }.first ?? fallbackScheme
        let arguments: [String] = [
            "-scheme",
            scheme,
            "-destination",
            "platform=iOS Simulator,name=\(iOSSimulator().name)",
            "test"
        ]

        return MuterConfiguration(executable: xcodeBuildExecutable,
                                  arguments: arguments,
                                  excludeList: swiftPackageManifestFiles(from: directoryContents))
    }

   private static func swiftDumpPackage(swiftExecutable: String) -> SwiftDumpPackage? {
        guard let swiftDumpPackageData = current.process().runProcess(url: swiftExecutable, arguments: ["package", "dump-package"]),
              let swiftDumpPackage = try? JSONDecoder().decode(SwiftDumpPackage.self, from: swiftDumpPackageData) else {
            return nil
        }

        return swiftDumpPackage
    }

    private static func swiftPackageSchemes(xcodebuildExecutable: String) -> [String] {
        guard let schemeOutputData = current.process().runProcess(url: xcodebuildExecutable, arguments: ["-list", "-quiet", "-json"]),
              let schemeOutput = try? JSONDecoder().decode(XcodeBuildSchemes.self, from: schemeOutputData) else {
            return []
        }

        return schemeOutput.workspace.schemes
    }

    private static func swiftPackageManifestFiles(from directoryContents: [URL]) -> [String] {
        directoryContents
            .include { $0.lastPathComponent.matches("Package@*.swift") }
            .map(\.lastPathComponent)
    }
}

extension MuterConfiguration {
    static func generateEmptyConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        MuterConfiguration(executable: "", arguments: [], excludeList: [])
    }
}

private struct SwiftDumpPackage: Codable {
    let name: String
    let platforms: [Platform]
    struct Platform: Codable {
        let platformName: String
    }
}

private struct XcodeBuildSchemes: Codable {
    let workspace: Workspace
    struct Workspace: Codable {
        let schemes: [String]
    }
}

private struct Simulator: Codable, CustomStringConvertible {
    let isAvailable: Bool
    let name: String
    let deviceTypeIdentifier: String

    var description: String { name }
}

extension Simulator {
    static var fallback: Simulator {
        Simulator(
            isAvailable: true,
            name: "iPhone SE (3rd generation)",
            deviceTypeIdentifier: ""
        )
    }
}

private func iOSSimulator() -> Simulator {
    let process = MuterProcessFactory.makeProcess()

    guard let simulatorsListOutput: Data = process.runProcess(
        url: "/usr/bin/xcrun",
        arguments: ["simctl", "list", "--json"]
    )
    else {
        return .fallback
    }

    do {
        let simulatorsJson = try (JSONSerialization.jsonObject(with: simulatorsListOutput) as? [String: AnyHashable]) ??
            [:]
        let devices = (simulatorsJson["devices"] as? [String: AnyHashable]) ?? [:]
        let newestRuntime = devices.keys.filter { $0.contains("iOS") }.sorted().last ?? ""
        let devicesForRunTime = (devices[newestRuntime] as? [AnyHashable]) ?? []
        let device = try devicesForRunTime
            .compactMap { try JSONSerialization.data(withJSONObject: $0) }
            .compactMap { try JSONDecoder().decode(Simulator.self, from: $0) }
            .filter(\.isAvailable)
            .sorted(by: { $0.deviceTypeIdentifier > $1.deviceTypeIdentifier })
            .first { $0.name.contains("iPhone") }

        return device ?? .fallback
    } catch {
        return .fallback
    }
}
