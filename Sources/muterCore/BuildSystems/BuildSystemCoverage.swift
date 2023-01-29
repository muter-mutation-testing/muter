import Foundation

// TODO: Move
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

typealias ProcessFactory = () -> Launchable

protocol BuildSystemCoverage: AnyObject {
    func run(
        process makeProcess: ProcessFactory,
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError>
}

enum CoverageError: Error {
    case build
}
