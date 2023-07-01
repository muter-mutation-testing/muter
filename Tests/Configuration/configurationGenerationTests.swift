@testable import muterCore
import XCTest

final class ConfigurationGenerationTests: MuterTestCase {
    func test_swiftPackageManagerProject() {
        let projectDirectoryContents = [
            "/some/path/Package.swift",
            "/some/path/main.swift"
        ]

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/usr/bin/swift",
                arguments: ["test"],
                excludeList: ["Package.swift"]
            )
        )
    }

    func test_xcodeProject() {
        let projectDirectoryContents = [
            "/some/path/Package.swift",
            "/some/path/main.swift",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
        ]

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/usr/bin/xcodebuild",
                arguments: [
                    "-project",
                    "iOSApp.xcodeproj",
                    "-scheme",
                    "iOSApp",
                    "-destination",
                    "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                    "test"
                ]
            )
        )
    }

    func test_iosProject() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "/some/path/AppDelegate.swift",
        ]

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/usr/bin/xcodebuild",
                arguments: [
                    "-project",
                    "iOSApp.xcodeproj",
                    "-scheme",
                    "iOSApp",
                    "-destination",
                    "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                    "test"
                ]
            )
        )
    }

    func test_xcodeWorkspace() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj/project.xcworkspace",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj/project.xcworkspace/contents.xcworkspacedata",
            "/some/path/AppDelegate.swift"
        ]

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/usr/bin/xcodebuild",
                arguments: [
                    "-project",
                    "iOSApp.xcodeproj",
                    "-scheme",
                    "iOSApp",
                    "-destination",
                    "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                    "test"
                ]
            )
        )
    }

    func test_macOSProject() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/CocoaApp.xcodeproj",
            "/some/path/AppDelegate.swift",
        ]

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/usr/bin/xcodebuild",
                arguments: [
                    "-project",
                    "CocoaApp.xcodeproj",
                    "-scheme",
                    "CocoaApp",
                    "test"
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

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/usr/bin/xcodebuild",
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

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(
                executable: "/usr/bin/xcodebuild",
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

    func test_unsupportedProject() {
        let generatedConfiguration = MuterConfiguration(from: ["/some/path/main.swift"])
        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(executable: "", arguments: [])
        )
    }
}
