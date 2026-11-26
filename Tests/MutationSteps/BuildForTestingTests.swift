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

    func test_copyBuildArtifactsFailed() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
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
        process.stdoutToBeReturned = xcodebuildBuildForTestingOutput()
        fileManager.contentsAtPathSortedToReturn = [""]

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .literal(reason: "Could not find xctestrun file at path: /path/to/temp/TestContents")
        )
    }

    func test_parseXCTestRunFails() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = xcodebuildBuildForTestingOutput()
        fileManager.contentsAtPathSortedToReturn = ["some/project.xctestrun"]

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .literal(reason: "Could not parse xctestrun at path: some/project.xctestrun")
        )
    }

    func test_whenBuildForTestingFails_thenReportsTheBuildErrors() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = """
        CompileSwift normal arm64 /path/to/temp/Sources/Module.swift
        /path/to/temp/Sources/Module.swift:4:7: error: cannot find 'foo' in scope
        /path/to/temp/Sources/Module.swift:4:7: error: cannot find 'foo' in scope
        ** TEST BUILD FAILED **
        """
        process.terminationStatus = 65

        do {
            _ = try await sut.run(with: state)
            XCTFail("Expected an error")
        } catch let MuterError.literal(reason) {
            XCTAssertTrue(reason.contains("build-for-testing failed (exit code 65)"), reason)
            XCTAssertEqual(reason.components(separatedBy: "error: cannot find 'foo' in scope").count, 2, reason)
            XCTAssertTrue(reason.contains("/path/to/xcodebuild some commands"), reason)
        }

        XCTAssertFalse(fileManager.methodCalls.contains("copyItem(atPath:toPath:)"))
    }

    func test_buildForTestingFailure_withoutErrorLines_showsTheEndOfTheOutput() {
        let output = (1 ... 30).map { "line \($0)" }.joined(separator: "\n")

        let message = BuildForTesting.buildForTestingFailure(output: output, exitCode: 70, command: "xcodebuild")

        XCTAssertTrue(message.contains("line 30"))
        XCTAssertTrue(message.contains("line 11"))
        XCTAssertFalse(message.contains("line 10\n"))
    }

    func test_productsDirectory_isWhereTheXCTestRunFileIs() {
        let project = URL(fileURLWithPath: "/path/to/temp")

        XCTAssertEqual(
            BuildForTesting.productsDirectory(
                ofXCTestRunAt: "/path/to/temp/TestContents/Build/Products/App_iphonesimulator.xctestrun",
                inProjectAt: project
            ),
            "TestContents/Build/Products/"
        )
        // The layout inside DerivedData is not documented, so a different folder must also work.
        XCTAssertEqual(
            BuildForTesting.productsDirectory(
                ofXCTestRunAt: "/path/to/temp/TestContents/Products/Debug/App.xctestrun",
                inProjectAt: project
            ),
            "TestContents/Products/Debug/"
        )
    }

    func test_productsDirectory_outsideTheProject_fallsBackToTheUsualFolder() {
        XCTAssertEqual(
            BuildForTesting.productsDirectory(
                ofXCTestRunAt: "some/project.xctestrun",
                inProjectAt: URL(fileURLWithPath: "/path/to/temp")
            ),
            "TestContents/Build/Products/"
        )
    }

    func test_xcTestRunPathsPointAtTheFolderWhereTheFileWasFound() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["some", "commands", "test"]
        )

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/temp")
        process.stdoutToBeReturned = xcodebuildBuildForTestingOutput()
        fileManager.contentsAtPathSortedToReturn = [
            "/path/to/temp/TestContents/Build/Intermediates.noindex/some.file",
            "/path/to/temp/TestContents/Products/App.xctestrun",
        ]
        fileManager.fileContentsToReturn = Data("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>AppTests</key>
            <dict>
                <key>TestHostPath</key>
                <string>__TESTROOT__/Debug-iphonesimulator/App.app</string>
            </dict>
        </dict>
        </plist>
        """.utf8)

        let result = try await sut.run(with: state)

        XCTAssertEqual(result, [
            .projectXCTestRun(XCTestRun([
                "AppTests": [
                    "TestHostPath": "__TESTROOT__/TestContents/Products/Debug-iphonesimulator/App.app",
                ] as [String: AnyHashable],
            ])),
        ])
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
