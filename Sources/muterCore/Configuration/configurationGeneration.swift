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
        guard !directoryContainsXcodeWorkspace(directoryContents),
            let index = directoryContents.firstIndex(where: { $0.lastPathComponent.contains(".xcodeproj") }),
            let arguments = arguments(forProjectFileAt: directoryContents[index], isWorkSpace: false) else {
            return nil
        }
        
        return MuterConfiguration(executable: "/usr/bin/xcodebuild",
                                  arguments: arguments)
    }
    
    static func generateXcodeWorkspaceConfiguration(from directoryContents: [URL]) -> MuterConfiguration? {
        guard directoryContainsXcodeWorkspace(directoryContents),
            let index = directoryContents.firstIndex(where: { $0.lastPathComponent.contains(".xcodeproj") }),
            let arguments = arguments(forProjectFileAt: directoryContents[index], isWorkSpace: true) else {
            return nil
        }
        
        return MuterConfiguration(executable: "/usr/bin/xcodebuild",
                                  arguments: arguments)
    }
    
    static func directoryContainsXcodeWorkspace(_ directoryContents: [URL]) -> Bool {
        return directoryContents.firstIndex(where: { $0.lastPathComponent.contains(".xcworkspace") }) != nil
    }
    
    static func arguments(forProjectFileAt url: URL, isWorkSpace: Bool) -> [String]? {
        guard let projectFile = try? String(contentsOf: url.appendingPathComponent("project.pbxproj"), encoding: .utf8),
            let projectName = url.lastPathComponent.split(separator: ".").first else {
            return nil
        }
        
        let defaultArguments = [
            isWorkSpace ? "-workspace" : "-project",
            isWorkSpace ? "\(projectName).xcworkspace" : "\(projectName).xcodeproj",
            "-scheme",
            "\(projectName)"
        ]
        
        let destination = projectFile.contains("SDKROOT = iphoneos") ?
            ["-destination", "platform=iOS Simulator,name=iPhone 8"] :
            []
        
        return defaultArguments + destination + ["test"]
    }
}

private extension MuterConfiguration {
    
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
