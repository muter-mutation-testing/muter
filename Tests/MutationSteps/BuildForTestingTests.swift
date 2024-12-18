#if !os(Linux)
@testable import muterCore
import TestingExtensions
import XCTest

final class BuildForTestingTests: MuterTestCase {
    private let state = MutationTestState()

    var buildDescriptionPath: String {
        fixturesDirectory + "/BuildForTesting"
    }

    private let sut = BuildForTesting()

    func test_whenBuildSystemIsSwift_thenIgnoreStep() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/swift"
        )

        let result = try await sut.run(with: state)

        XCTAssertEqual(result, [])
    }

    // MARK: xcodebuild

    func test_changeCurrentPathToTempDirectory() async throws {
        fileManager.currentDirectoryPathToReturn = "/path/to/project"

        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild"
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")

        do { _ = try await sut.run(with: state) }
        catch {}

        XCTAssertTrue(fileManager.methodCalls.contains("changeCurrentDirectoryPath(_:)"))
        XCTAssertEqual(
            fileManager.changeCurrentDirectoryPath.first,
            state.mutatedProjectDirectoryURL.path
        )
    }

    func test_resetCurrentPath() {
        fileManager.currentDirectoryPathToReturn = "/path/to/project"

        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild"
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")

        XCTAssertEqual(fileManager.methodCalls, [])
        XCTAssertEqual(
            fileManager.currentDirectoryPath,
            "/path/to/project"
        )
    }

    func test_runShowBuildSettings() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        process.stdoutToBeReturned = ""

        _ = try? await sut.run(with: state)

        XCTAssertEqual(process.executableURL?.path, "/path/to/xcodebuild")
        XCTAssertEqual(process.arguments, ["-showBuildSettings"])
    }

    func test_whenCannotParseBuildDirectoryThenThrowError() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        process.stdoutToBeReturned = ""

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .literal(reason: "Could not find `BUILD_DIR`")
        )
    }

    func test_copyBuildArtifactsFailed() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = xcodebuildShowBuildSettingsOutput()
        process.stdoutToBeReturned = xcodebuildBuildForTestingOutput()
        fileManager.errorToThrow = TestingError.stub

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .literal(reason: "stub")
        )
    }

    func test_findMostRecentXCTestRunFails() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = xcodebuildShowBuildSettingsOutput()
        process.stdoutToBeReturned = xcodebuildBuildForTestingOutput()
        fileManager.contentsAtPathSortedToReturn = [""]

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .literal(reason: "Could not find xctestrun file at path: /path/to/temp/Debug")
        )
    }

    func test_parseXCTestRunFails() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = xcodebuildShowBuildSettingsOutput()
        process.stdoutToBeReturned = xcodebuildBuildForTestingOutput()
        fileManager.contentsAtPathSortedToReturn = ["some/project.xctestrun"]

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .literal(reason: "Could not parse xctestrun at path: some/project.xctestrun")
        )
    }
    
    func test_supportsCustomDerivedDataPath() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: [
                "some",
                "commands",
                "-derivedDataPath",
                "/path/to/custom_derived_Data_path",
                "test"
            ]
        )
        
        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = xcodebuildBuildForTestingOutput()
        
        _ = try? await sut.run(with: state)
        XCTAssertTrue(fileManager.copyPaths.contains(where: { $0.source == "/path/to/custom_derived_Data_path/Build/Products" && $0.dest == "/path/to/temp/Debug" }))
        
    }

    private func xcodebuildBuildForTestingOutput() -> String {
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

    private func xcodebuildShowBuildSettingsOutput() -> String {
        """
        AUTOMATICALLY_MERGE_DEPENDENCIES = NO
            AVAILABLE_PLATFORMS = appletvos appletvsimulator driverkit iphoneos iphonesimulator macosx watchos watchsimulator
            BITCODE_GENERATION_MODE = marker
            BUILD_ACTIVE_RESOURCES_ONLY = NO
            BUILD_COMPONENTS = headers build
            BUILD_DIR = /user/Library/Developer/Xcode/DerivedData/App-gkbxrvayhpqhtperezjiwgahsiuy/Build/Products
            BUILD_LIBRARY_FOR_DISTRIBUTION = NO
            BUILD_ROOT = /user/Library/Developer/Xcode/DerivedData/App-gkbxrvayhpqhtperezjiwgahsiuy/Build/Products
            BUILD_STYLE =
            BUILD_VARIANTS = normal
            BUILT_PRODUCTS_DIR = /user/Library/Developer/Xcode/DerivedData/App-gkbxrvayhpqhtperezjiwgahsiuy/Build/Products/Release-iphoneos
            BUNDLE_CONTENTS_FOLDER_PATH_deep = Contents/
            BUNDLE_EXECUTABLE_FOLDER_NAME_deep = MacOS
            BUNDLE_EXTENSIONS_FOLDER_PATH = Extensions
            BUNDLE_FORMAT = shallow
            BUNDLE_FRAMEWORKS_FOLDER_PATH = Frameworks
            BUNDLE_PLUGINS_FOLDER_PATH = PlugIns
            BUNDLE_PRIVATE_HEADERS_FOLDER_PATH = PrivateHeaders
            BUNDLE_PUBLIC_HEADERS_FOLDER_PATH = Headers
        """
    }

    private func loadXCTestRun() -> Data {
        FileManager.default.contents(atPath: buildDescriptionPath + "/project.xctestrun") ?? .init()
    }

    private func loadXCTestRunWithDebugFolder() -> Data {
        FileManager.default.contents(atPath: buildDescriptionPath + "/projectWithDebugPath.xctestrun") ?? .init()
    }
}

extension muterCore.XCTestRun {
    static func from(_ data: Data) -> Self {
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: AnyHashable]

        return .init(plist ?? [:])
    }
}
#endif
