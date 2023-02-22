import Foundation

enum BuildSystem: String {
    case xcodebuild
    case swift
    case unknown

    init(rawValue: String) {
        switch rawValue {
        case "swift": self = .swift
        case "xcodebuild": self = .xcodebuild
        default: self = .unknown
        }
    }
}

extension BuildSystem {
    static func coverage(
        for buildSystem: BuildSystem
    ) -> BuildSystemCoverage? {
        switch buildSystem {
        case .swift: return SwiftCoverage()
        case .xcodebuild: return XcodeCoverage()
        default: return nil
        }
    }
}

protocol BuildSystemCoverage: AnyObject {
    var process: ProcessFactory { get }

    func run(
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError>
}

enum CoverageError: Error {
    case build
}
