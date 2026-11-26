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
        guard let manifest = directoryContents.first(where: { $0.lastPathComponent == "Package.swift" }) else {
            return nil
        }

        let swift = executablePath("swift")
        let excludeList = swiftPackageManifestFiles(from: directoryContents)

        // `swift test` builds for macOS. A package that supports iOS but not macOS (it imports UIKit,
        // for example) only builds with xcodebuild and an iOS Simulator destination.
        if let package = PackageDump(swift: swift, packageDirectory: manifest.deletingLastPathComponent()),
           package.supportsIOSButNotMacOS {
            let scheme = packageScheme(for: package.name)
            let destination = "platform=iOS Simulator,name=\(iosDestination())"

            return MuterConfiguration(
                executable: executablePath("xcodebuild"),
                arguments: ["-scheme", scheme, "-destination", destination, "test"],
                excludeList: excludeList
            )
        }

        return MuterConfiguration(
            executable: swift,
            arguments: ["test"],
            excludeList: excludeList
        )
    }

    /// The scheme Xcode creates for the package: `<name>-Package` when the package has several
    /// products, otherwise the package's name.
    private static func packageScheme(for packageName: String) -> String {
        let xcodebuild = executablePath("xcodebuild")
        let schemes = current.process()
            .runProcess(url: xcodebuild, arguments: ["-list", "-json"])
            .flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONDecoder().decode(XcodebuildList.self, from: $0) }?
            .workspace?
            .schemes ?? []

        return ["\(packageName)-Package", packageName].first(where: schemes.contains) ?? packageName
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

            // A runtime newer than the active Xcode supports lists its devices as unavailable,
            // so walk runtimes newest first and take the first with a usable iPhone.
            let runtimesNewestFirst = devices.keys
                .filter { $0.contains("iOS") }
                .sorted { runtimeVersion($0).lexicographicallyPrecedes(runtimeVersion($1)) }
                .reversed()

            for runtime in runtimesNewestFirst {
                let devicesForRunTime = (devices[runtime] as? [AnyHashable]) ?? []
                let device: Simulator? = try devicesForRunTime
                    .compactMap { try JSONSerialization.data(withJSONObject: $0) }
                    .compactMap { try JSONDecoder().decode(Simulator.self, from: $0) }
                    .filter(\.isAvailable)
                    .sorted(by: { $0.deviceTypeIdentifier > $1.deviceTypeIdentifier })
                    .first { $0.name.contains("iPhone") }

                if let device {
                    return device.name
                }
            }

            return Simulator.fallback.name
        } catch {
            return Simulator.fallback.name
        }
    }

    /// `com.apple.CoreSimulator.SimRuntime.iOS-26-3` -> `[26, 3]`
    private static func runtimeVersion(_ runtime: String) -> [Int] {
        let version = runtime.components(separatedBy: "iOS-").last ?? ""
        return version.split(separator: "-").compactMap { Int($0) }
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

/// The parts of `swift package dump-package` that decide how to build the package.
private struct PackageDump: Decodable {
    struct Platform: Decodable {
        let platformName: String
    }

    let name: String
    let platforms: [Platform]?

    var supportsIOSButNotMacOS: Bool {
        let names = (platforms ?? []).map { $0.platformName.lowercased() }
        return names.contains("ios") && !names.contains("macos")
    }

    init?(swift: String, packageDirectory: URL) {
        guard !swift.isEmpty,
              let output: String = current.process().runProcess(
                  url: swift,
                  arguments: ["package", "--package-path", packageDirectory.path, "dump-package"]
              ),
              let data = output.data(using: .utf8),
              let dump = try? JSONDecoder().decode(PackageDump.self, from: data)
        else {
            return nil
        }

        self = dump
    }
}

/// The part of `xcodebuild -list -json` that lists a package's schemes.
private struct XcodebuildList: Decodable {
    struct Workspace: Decodable {
        let schemes: [String]
    }

    let workspace: Workspace?
}
