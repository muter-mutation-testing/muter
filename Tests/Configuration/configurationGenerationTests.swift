@testable import muterCore
import XCTest

final class ConfigurationGenerationTests: MuterTestCase {
    func test_swiftPackageManagerProject() {
        let projectDirectoryContents = [
            "/some/path/Package.swift",
            "/some/path/Package@swift-5.11.swift",
            "/some/path/main.swift",
            "/some/path/PackageIgnoreMe.swift"
        ]

        process.stdoutToBeReturned = which("swift")

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

    func test_swiftPackageThatSupportsMacOS_usesSwiftTest() {
        process.stdoutToBeReturned = which("swift")
        process.stdoutToBeReturned = packageDump(platforms: ["ios", "macos"])

        let generatedConfiguration = MuterConfiguration(from: ["/some/path/Package.swift"])

        XCTAssertEqual(
            generatedConfiguration,
            MuterConfiguration(executable: "/path/to/swift", arguments: ["test"], excludeList: ["Package.swift"])
        )
    }

    private func packageDump(platforms: [String]) -> String {
        let list = platforms.map { #"{ "platformName": "\#($0)", "version": "15.0", "options": [] }"# }
        return #"{ "name": "IOSCore", "platforms": [\#(list.joined(separator: ", "))] }"#
    }

    #if !os(Linux)
    func test_swiftPackageForIOSOnly_usesXcodebuildWithAnIOSSimulator() {
        // `swift test` builds for macOS, so a package that imports UIKit only builds with xcodebuild (#296).
        process.stdoutToBeReturned = which("swift")
        process.stdoutToBeReturned = packageDump(platforms: ["ios"])
        process.stdoutToBeReturned = which("xcodebuild")
        process.stdoutToBeReturned = #"{ "workspace": { "name": "IOSCore", "schemes": ["IOSCore"] } }"#
        process.stdoutToBeReturned = simCtl()
        process.stdoutToBeReturned = which("xcodebuild")

        let generatedConfiguration = MuterConfiguration(from: ["/some/path/Package.swift"])

        XCTAssertEqual(generatedConfiguration.testCommandExecutable, "/path/to/xcodebuild")
        XCTAssertEqual(
            generatedConfiguration.testCommandArguments.filter { !$0.contains("platform") },
            ["-scheme", "IOSCore", "-destination", "test"]
        )
        XCTAssertNotNil(
            generatedConfiguration.testCommandArguments.first { $0.hasPrefix("platform=iOS Simulator,name=") }
        )
        XCTAssertEqual(generatedConfiguration.excludeFileList, ["Package.swift"])
    }

    func test_swiftPackageForIOSOnly_withSeveralProducts_usesThePackageScheme() {
        process.stdoutToBeReturned = which("swift")
        process.stdoutToBeReturned = packageDump(platforms: ["ios"])
        process.stdoutToBeReturned = which("xcodebuild")
        process.stdoutToBeReturned = #"{ "workspace": { "name": "IOSCore", "schemes": ["Core", "IOSCore-Package", "UI"] } }"#
        process.stdoutToBeReturned = simCtl()
        process.stdoutToBeReturned = which("xcodebuild")

        let generatedConfiguration = MuterConfiguration(from: ["/some/path/Package.swift"])

        XCTAssertEqual(generatedConfiguration.testCommandArguments.prefix(2), ["-scheme", "IOSCore-Package"])
    }

    func test_xcodeProject() {
        let projectDirectoryContents = [
            "/some/path/Package.swift",
            "/some/path/main.swift",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj"
        ]

        process.stdoutToBeReturned = simCtl()
        process.stdoutToBeReturned = which("xcodebuild")

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        let expectedConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
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

        XCTAssertEqual(generatedConfiguration.testCommandExecutable, expectedConfiguration.testCommandExecutable)
        XCTAssertEqual(
            generatedConfiguration.testCommandArguments.filter { !$0.contains("platform") },
            expectedConfiguration.testCommandArguments.filter { !$0.contains("platform") }
        )
        XCTAssertNotNil(
            generatedConfiguration.testCommandArguments
                .first { $0.contains("platform=iOS Simulator,name=iPhone") }
        )
    }

    func test_iosProject() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "/some/path/AppDelegate.swift"
        ]

        process.stdoutToBeReturned = simCtl()
        process.stdoutToBeReturned = which("xcodebuild")

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        let expectedConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
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

        XCTAssertEqual(generatedConfiguration.testCommandExecutable, expectedConfiguration.testCommandExecutable)
        XCTAssertEqual(
            generatedConfiguration.testCommandArguments.filter { !$0.contains("platform") },
            expectedConfiguration.testCommandArguments.filter { !$0.contains("platform") }
        )
        XCTAssertNotNil(
            generatedConfiguration.testCommandArguments
                .first { $0.contains("platform=iOS Simulator,name=iPhone") }
        )
    }

    func test_iosProject_whenNewestRuntimeHasNoAvailableDevices_thenUseNewestRuntimeThatDoes() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "/some/path/AppDelegate.swift"
        ]

        process.stdoutToBeReturned = simCtlWithUnsupportedNewestRuntime()
        process.stdoutToBeReturned = which("xcodebuild")

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        XCTAssertTrue(
            generatedConfiguration.testCommandArguments
                .contains("platform=iOS Simulator,name=iPhone 17 Pro")
        )
    }

    func test_xcodeWorkspace() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj/project.xcworkspace",
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj/project.xcworkspace/contents.xcworkspacedata",
            "/some/path/AppDelegate.swift"
        ]

        process.stdoutToBeReturned = simCtl()
        process.stdoutToBeReturned = which("xcodebuild")

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        let expectedConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
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

        XCTAssertEqual(generatedConfiguration.testCommandExecutable, expectedConfiguration.testCommandExecutable)
        XCTAssertEqual(
            generatedConfiguration.testCommandArguments.filter { !$0.contains("platform") },
            expectedConfiguration.testCommandArguments.filter { !$0.contains("platform") }
        )
        XCTAssertNotNil(
            generatedConfiguration.testCommandArguments
                .first { $0.contains("platform=iOS Simulator,name=iPhone") }
        )
    }

    func test_macOSProject() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/CocoaApp.xcodeproj",
            "/some/path/AppDelegate.swift"
        ]

        process.stdoutToBeReturned = macOSDescitionation()
        process.stdoutToBeReturned = which("xcodebuild")

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
                    "-destination",
                    "platform=macOS,arch=arm64,id=00006000-000A38D61E02401E,name=My Mac",
                    "test"
                ]
            )
        )
    }

    func test_iosWorkspace() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
            "/some/path/iOSApp.xcworkspace", // does not need to be a real file - just needs to share a name
            "/some/path/AppDelegate.swift"
        ]

        process.stdoutToBeReturned = simCtl()
        process.stdoutToBeReturned = which("xcodebuild")

        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)

        let expectedConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: [
                "-workspace",
                "iOSApp.xcworkspace",
                "-scheme",
                "iOSApp",
                "-destination",
                "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                "test"
            ]
        )

        XCTAssertEqual(generatedConfiguration.testCommandExecutable, expectedConfiguration.testCommandExecutable)
        XCTAssertEqual(
            generatedConfiguration.testCommandArguments.filter { !$0.contains("platform") },
            expectedConfiguration.testCommandArguments.filter { !$0.contains("platform") }
        )
        XCTAssertNotNil(
            generatedConfiguration.testCommandArguments
                .first { $0.contains("platform=iOS Simulator,name=iPhone") }
        )
    }

    func test_macOSWorkspace() {
        let projectDirectoryContents = [
            "\(fixturesDirectory)/XcodeProjectFiles/CocoaApp.xcodeproj",
            "/some/path/CocoaApp.xcworkspace", // does not need to be a real file - just needs to share a name
            "/some/path/AppDelegate.swift"
        ]

        process.stdoutToBeReturned = macOSDescitionation()
        process.stdoutToBeReturned = which("xcodebuild")

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
                    "-destination",
                    "platform=macOS,arch=arm64,id=00006000-000A38D61E02401E,name=My Mac",
                    "test"
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

    private func simCtl() -> String {
        """
        {
            "devicetypes":
            [
                {
                    "productFamily": "iPhone",
                    "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 14 Plus.simdevicetype",
                    "maxRuntimeVersion": 4294967295,
                    "maxRuntimeVersionString": "65535.255.255",
                    "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus",
                    "modelIdentifier": "iPhone14,8",
                    "minRuntimeVersionString": "16.0.0",
                    "minRuntimeVersion": 1048576,
                    "name": "iPhone 14 Plus"
                },
                {
                    "productFamily": "iPhone",
                    "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone SE (3rd generation).simdevicetype",
                    "maxRuntimeVersion": 4294967295,
                    "maxRuntimeVersionString": "65535.255.255",
                    "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
                    "modelIdentifier": "iPhone14,6",
                    "minRuntimeVersionString": "15.4.0",
                    "minRuntimeVersion": 984064,
                    "name": "iPhone SE (3rd generation)"
                }
            ]
        }
        """
    }

    private func simCtlWithUnsupportedNewestRuntime() -> String {
        """
        {
            "devices": {
                "com.apple.CoreSimulator.SimRuntime.iOS-9-3": [
                    {
                        "isAvailable": true,
                        "name": "iPhone 6s",
                        "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-6s"
                    }
                ],
                "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
                    {
                        "isAvailable": true,
                        "name": "iPhone 17 Pro",
                        "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
                    }
                ],
                "com.apple.CoreSimulator.SimRuntime.iOS-26-3": [
                    {
                        "isAvailable": false,
                        "name": "iPhone 17 Pro Max",
                        "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"
                    }
                ]
            }
        }
        """
    }

    private func macOSDescitionation() -> String {
        """
            [MT] IDERunDestination: Supported platforms for the buildables in the current scheme is empty.


                Available destinations for the "ExampleMacOSApp" scheme:
                    { platform:macOS, arch:arm64, id:00006000-000A38D61E02401E, name:My Mac }
                    { platform:macOS, name:Any Mac }
        """
    }

    func which(_ program: String) -> String {
        "/path/to/\(program)"
    }
}
