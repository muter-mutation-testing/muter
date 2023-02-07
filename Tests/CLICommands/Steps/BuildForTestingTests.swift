import XCTest
import TestingExtensions

@testable import muterCore

final class BuildForTestingTests: XCTestCase {
    private let state = RunCommandState()
    private let fileManager = FileManagerSpy()
    private let notificationCenter = NotificationCenter()
    private let process = LaunchableSpy()

    var buildDescriptionPath: String {
        fixturesDirectory + "/BuildForTesting"
    }

    private lazy var sut = BuildForTesting(
        process: self.process,
        fileManager: fileManager,
        notificationCenter: notificationCenter
    )

    func test_whenBuildSystemIsSwift_thenIgnoreStep() throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/swift"
        )

        let result = try sut.run(with: state).get()

        XCTAssertEqual(result, [])
    }
    

    // MARK: xcodebuild

    func test_changeCurrentPathToTempDirectory() throws {
        fileManager.currentDirectoryPathToReturn = "/path/to/project"

        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild"
        )
        
        state.tempDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        
        _ = sut.run(with: state)
        
        XCTAssertTrue(fileManager.methodCalls.contains("changeCurrentDirectoryPath(_:)"))
        XCTAssertEqual(
            fileManager.changeCurrentDirectoryPath.first,
            state.tempDirectoryURL.path
        )
    }
    
    func test_resetCurrentPath() {
        fileManager.currentDirectoryPathToReturn = "/path/to/project"

        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild"
        )
        
        state.tempDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        
        XCTAssertEqual(fileManager.methodCalls, [])
        XCTAssertEqual(
            fileManager.currentDirectoryPath,
            "/path/to/project"
        )
    }

    func test_runBuildWithoutTestCommand() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        _ = sut.run(with: state)

        XCTAssertEqual(process.executableURL?.absoluteString, "file:///path/to/xcodebuild")
        XCTAssertEqual(process.arguments, ["some", "commands", "build-for-testing"])
        XCTAssertTrue(process.runCalled)
        XCTAssertTrue(process.waitUntilExitCalled)
    }

    func test_parseBuildDescriptionPath() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        process.stdoutToBeReturned = makeBuildForTestingLog()

        _ = sut.run(with: state)

        XCTAssertEqual(process.executableURL?.absoluteString, "file:///path/to/xcodebuild")
        XCTAssertEqual(process.arguments, ["some", "commands", "build-for-testing"])
        XCTAssertTrue(process.runCalled)
        XCTAssertTrue(process.waitUntilExitCalled)

        XCTAssertTrue(fileManager.methodCalls.contains("contents(atPath:)"))
    }

    func test_copyBuildProductsPathContents() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.tempDirectoryURL = URL(fileURLWithPath: "/path/to/temp")

        process.stdoutToBeReturned = makeBuildForTestingLog()

        fileManager.fileContentsToReturn = makeBuildRequestJson().data(using: .utf8)

        _ = sut.run(with: state)

        XCTAssertEqual(process.executableURL?.absoluteString, "file:///path/to/xcodebuild")
        XCTAssertEqual(process.arguments, ["some", "commands", "build-for-testing"])
        XCTAssertTrue(process.runCalled)
        XCTAssertTrue(process.waitUntilExitCalled)

        XCTAssertTrue(fileManager.methodCalls.contains("removeItem(atPath:)"))
        XCTAssertEqual(fileManager.paths, ["/path/to/temp/Debug"])

        XCTAssertTrue(fileManager.methodCalls.contains("copyItem(atPath:toPath:)"))
        XCTAssertEqual(fileManager.copyPaths.first?.source, buildDescriptionPath)
        XCTAssertEqual(fileManager.copyPaths.first?.dest, "/path/to/temp/Debug")
    }

    func test_parseXCTestRun() throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.tempDirectoryURL = URL(fileURLWithPath: "/path/to/temp")

        process.stdoutToBeReturned = makeBuildForTestingLog()

        fileManager.fileContentsToReturn = makeBuildRequestJson().data(using: .utf8)
        fileManager.contentsAtPathSortedToReturn = [buildDescriptionPath + "/project.xctestrun"]
        fileManager.fileContentsToReturn = loadXCTestRun()

        let result = try sut.run(with: state).get()

        XCTAssertEqual(fileManager.contentsAtPathSorted, ["/path/to/temp/Debug"])
        XCTAssertEqual(fileManager.contentsAtPathSortedOrder, [.orderedDescending])
        XCTAssertEqual(result, [
            .projectXCTestRun(.from(loadXCTestRun()))
        ])
    }

    func test_buildForTestingFailed() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        process.stdoutToBeReturned = ""

        let result = sut.run(with: state)

        XCTAssertEqual(
            result,
            .failure(.literal(reason: "Could not run test with -build-for-testing argument"))
        )
    }

    func test_findBuildRequestJsonFailed() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        process.stdoutToBeReturned = "im not important"

        let result = sut.run(with: state)

        XCTAssertEqual(
            result,
            .failure(.literal(reason: "Could not parse buildRequest.json from build description path"))
        )
    }

    func test_parseBuildRequestJsonFailed() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.tempDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = makeBuildForTestingLog()

        let result = sut.run(with: state)

        guard case let .failure(.literal(reason)) = result else {
            return XCTFail("Expected failure, got\(result)")
        }

        XCTAssertFalse(reason.isEmpty)

        XCTAssertTrue(
            reason.contains("Could not parse build request json at path")
        )
    }

    func test_copyBuildArtifactsFailed() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.tempDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = makeBuildForTestingLog()
        fileManager.fileContentsToReturn = makeBuildRequestJson().data(using: .utf8)
        fileManager.errorToThrow = TestingError.stub

        let result = sut.run(with: state)

        guard case let .failure(.literal(reason)) = result else {
            return XCTFail("Expected failure, got\(result)")
        }

        XCTAssertFalse(reason.isEmpty)
    }

    func test_findMostRecentXCTestRunFails() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.tempDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = makeBuildForTestingLog()
        fileManager.fileContentsToReturn = makeBuildRequestJson().data(using: .utf8)
        fileManager.contentsAtPathSortedToReturn = [""]

        let result = sut.run(with: state)

        XCTAssertEqual(
            result,
            .failure(.literal(reason: "Could not find xctestrun file at path: /path/to/temp/Debug"))
        )
    }

    func test_parseXCTestRunFails() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.tempDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = makeBuildForTestingLog()
        fileManager.fileContentsToReturn = makeBuildRequestJson().data(using: .utf8)
        fileManager.contentsAtPathSortedToReturn = ["some/project.xctestrun"]

        let result = sut.run(with: state)

        XCTAssertEqual(
            result,
            .failure(.literal(reason: "Could not parse xctestrun at path: some/project.xctestrun"))
        )
    }

    private func makeBuildForTestingLog() -> String {
        """
        Command line invocation:
            /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project iOSProject.xcodeproj -scheme iOSProject -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)" build-for-testing

        User defaults from command line:
            IDEPackageSupportUseBuiltinSCM = YES

        Prepare packages

        Computing target dependency graph and provisioning inputs

        Create build description
        Build description signature: a57afb1c7ff29046be11d242c417308a
        Build description path: \(buildDescriptionPath)/desc.xcbuild


        ** TEST BUILD SUCCEEDED **
        """
    }

    private func makeBuildRequestJson() -> String {
        """
        {
          "_buildCommand2" : {
            "command" : "build",
            "skipDependencies" : false,
            "style" : "buildOnly"
          },
          "buildCommand" : "build",
          "configuredTargets" : [
            {
              "guid" : "d40d24f2f9d993f710521f28a51248b77847c6fdfdb308788f5cd5ad7eab5cb3"
            }
          ],
          "containerPath" : "/path/to/project/iOSProject/iOSProject.xcodeproj",
          "continueBuildingAfterErrors" : false,
          "enableIndexBuildArena" : false,
          "hideShellScriptEnvironment" : false,
          "parameters" : {
            "action" : "build",
            "activeArchitecture" : "arm64",
            "activeRunDestination" : {
              "disableOnlyActiveArch" : false,
              "platform" : "iphonesimulator",
              "sdk" : "iphonesimulator16.1",
              "sdkVariant" : "iphonesimulator",
              "supportedArchitectures" : [
                "arm64",
                "x86_64"
              ],
              "targetArchitecture" : "arm64"
            },
            "arenaInfo" : {
              "buildIntermediatesPath" : "/path/to/Library/Developer/Xcode/DerivedData/iOSProject-cimyyvjteyjtkmazpzxttpvpzcnp/Build/Intermediates.noindex",
              "buildProductsPath" : "\(buildDescriptionPath)",
              "derivedDataPath" : "/path/to/Library/Developer/Xcode/DerivedData",
              "indexDataStoreFolderPath" : "/path/to/Library/Developer/Xcode/DerivedData/iOSProject-cimyyvjteyjtkmazpzxttpvpzcnp/Index.noindex/DataStore",
              "indexEnableDataStore" : true,
              "indexPCHPath" : "/path/to/Library/Developer/Xcode/DerivedData/iOSProject-cimyyvjteyjtkmazpzxttpvpzcnp/Index.noindex/PrecompiledHeaders",
              "pchPath" : "/path/to/Library/Developer/Xcode/DerivedData/iOSProject-cimyyvjteyjtkmazpzxttpvpzcnp/Build/Intermediates.noindex/PrecompiledHeaders"
            },
            "configurationName" : "Debug",
            "overrides" : {
              "synthesized" : {
                "table" : {
                  "ASSETCATALOG_FILTER_FOR_DEVICE_MODEL" : "iPhone14,6",
                  "ASSETCATALOG_FILTER_FOR_DEVICE_OS_VERSION" : "16.1",
                  "ASSETCATALOG_FILTER_FOR_THINNING_DEVICE_CONFIGURATION" : "iPhone14,6",
                  "BUILD_ACTIVE_RESOURCES_ONLY" : "YES",
                  "ENABLE_PREVIEWS" : "NO",
                  "TARGET_DEVICE_IDENTIFIER" : "FDA1B2B9-B6CC-4B38-B8DF-DE452FD8EF18",
                  "TARGET_DEVICE_MODEL" : "iPhone14,6",
                  "TARGET_DEVICE_OS_VERSION" : "16.1",
                  "TARGET_DEVICE_PLATFORM_NAME" : "iphonesimulator"
                }
              }
            }
          },
          "schemeCommand" : "launch",
          "schemeCommand2" : "launch",
          "showNonLoggedProgress" : true,
          "useDryRun" : false,
          "useImplicitDependencies" : true,
          "useLegacyBuildLocations" : false,
          "useParallelTargets" : true
        }
        """
    }

    private func loadXCTestRun() -> Data {
        FileManager.default.contents(atPath: buildDescriptionPath + "/project.xctestrun") ?? .init()
    }
}

extension muterCore.XCTestRun {
    static func from(_ data: Data) -> Self {
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: AnyHashable]

        return .init(plist ?? [:])
    }
}
