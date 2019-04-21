import Foundation

extension MuterConfiguration {
    private static let generators = [generateXcodeProjectConfiguration,
                                     generateXcodeWorkspaceConfiguration,
                                     generateSPMConfiguration,
                                     generateEmptyConfiguration]
    
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
        guard let index = directoryContents.firstIndex(where: { $0.lastPathComponent.contains(".xcodeproj") }),
            let arguments = arguments(forProjectFileAt: directoryContents[index]) else {
            return nil
        }
        
        return MuterConfiguration(executable: "/usr/bin/xcodebuild",
                                  arguments: arguments)
    }
    
    static func arguments(forProjectFileAt url: URL) -> [String]? {
        guard let projectFile = try? String(contentsOf: url.appendingPathComponent("project.pbxproj"), encoding: .utf8) else {
            return nil
        }
        
        let defaultArguments = [
            "-project",
            "\(url.lastPathComponent)",
            "-scheme",
            "\(url.lastPathComponent.split(separator: ".").first!)"
        ]
        
        let destination = projectFile.contains("SDKROOT = iphoneos") ?
            ["-destination", "platform=iOS Simulator,name=iPhone 8"] :
            []
        
        return defaultArguments + destination + ["test"]
    }
    
    static func generateXcodeWorkspaceConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        guard let index = directoryContents.firstIndex(where: { $0.lastPathComponent.contains(".xcworkspace") }) else {
            return nil
        }
        
        let fileUrl = directoryContents[index]
        return MuterConfiguration(executable: "/usr/bin/xcodebuild",
                                  arguments: [
                                    "-workspace",
                                    "\(fileUrl.lastPathComponent)",
                                    "-scheme",
                                    "\(fileUrl.lastPathComponent.split(separator: ".").first!)",
                                    "-destination",
                                    "platform=iOS Simulator,name=iPhone 8",
                                    "test"
                                  ],
                                  excludeList: [])
    }
    
    static func generateSPMConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        if directoryContents.contains(where: { $0.lastPathComponent == "Package.swift" }) {
            return MuterConfiguration(executable: "/usr/bin/swift", arguments: ["test"], excludeList: [])
        }
        
        return nil
    }
    
    static func generateEmptyConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        return MuterConfiguration(executable: "", arguments: [], excludeList: [])
    }
}
