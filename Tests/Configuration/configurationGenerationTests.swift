@testable import muterCore
import XCTest

final class ConfigurationGenerationTests: MuterTestCase {
    func test_swiftPackageManagerProject() {
        let projectDirectoryContents = [
            "/some/path/Package.swift",
            "/some/path/Package@swift-5.11.swift",
            "/some/path/main.swift",
        ]

        process.stdoutToBeReturned = "/path/to/swift"

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/path/to/swift",
                arguments: ["test"],
                excludeList: ["Package.swift", "Package@swift-5.11.swift"]
            )
        )
    }

    #if !os(Linux)
    func test_xcodeProject() {
        let projectDirectoryContents = [
            "/some/path/Package.swift",
            "/some/path/main.swift",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
        ]

        process.stdoutToBeReturned = "/path/to/xcodebuild"

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/path/to/xcodebuild",
                arguments: [
                    "-project",
                    "iOSApp.xcodeproj",
                    "-scheme",
                    "iOSApp",
                    "-destination",
                    "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                    "test",
                ]
            )
        )
    }

    func test_iosProject() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "/some/path/AppDelegate.swift",
        ]

        process.stdoutToBeReturned = "/path/to/xcodebuild"

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/path/to/xcodebuild",
                arguments: [
                    "-project",
                    "iOSApp.xcodeproj",
                    "-scheme",
                    "iOSApp",
                    "-destination",
                    "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                    "test",
                ]
            )
        )
    }

    func test_xcodeWorkspace() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj/project.xcworkspace",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj/project.xcworkspace/contents.xcworkspacedata",
            "/some/path/AppDelegate.swift",
        ]

        process.stdoutToBeReturned = "/path/to/xcodebuild"

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/path/to/xcodebuild",
                arguments: [
                    "-project",
                    "iOSApp.xcodeproj",
                    "-scheme",
                    "iOSApp",
                    "-destination",
                    "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                    "test",
                ]
            )
        )
    }

    func test_macOSProject() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/CocoaApp.xcodeproj",
            "/some/path/AppDelegate.swift",
        ]

        process.stdoutToBeReturned = "/path/to/xcodebuild"

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/path/to/xcodebuild",
                arguments: [
                    "-project",
                    "CocoaApp.xcodeproj",
                    "-scheme",
                    "CocoaApp",
                    "test",
                ]
            )
        )
    }

    func test_iosWorkspace() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "/some/path/iOSApp.xcworkspace", // does not need to be a real file - just needs to share a name
            "/some/path/AppDelegate.swift",
        ]

        process.stdoutToBeReturned = "/path/to/xcodebuild"

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/path/to/xcodebuild",
                arguments: [
                    "-workspace",
                    "iOSApp.xcworkspace",
                    "-scheme",
                    "iOSApp",
                    "-destination",
                    "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                    "test",
                ]
            )
        )
    }

    func test_macOSWorkspace() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/CocoaApp.xcodeproj",
            "/some/path/CocoaApp.xcworkspace", // does not need to be a real file - just needs to share a name
            "/some/path/AppDelegate.swift",
        ]

        process.stdoutToBeReturned = "/path/to/xcodebuild"

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/path/to/xcodebuild",
                arguments: [
                    "-workspace",
                    "CocoaApp.xcworkspace",
                    "-scheme",
                    "CocoaApp",
                    "test",
                ]
            )
        )
    }
    #endif

    func test_unsupportedProject() {
        let generatedConfiguration = MuterConfiguration(from: ["/some/path/main.swift"])
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(executable: "", arguments: [])
        )
    }
}
