@testable import muterCore
import SwiftParser
import SwiftSyntax
import TestingExtensions
import XCTest

final class TargetPlatformTests: MuterTestCase {
    private let macOS = TargetPlatform(os: .macOS, isSimulator: false)
    private let iOSSimulator = TargetPlatform(os: .iOS, isSimulator: true)
    private let iOSDevice = TargetPlatform(os: .iOS, isSimulator: false)

    private func xcodebuild(_ destinations: String...) -> TargetPlatform? {
        TargetPlatform(configuration: MuterConfiguration(
            executable: "/usr/bin/xcodebuild",
            arguments: ["-scheme", "App"] + destinations.flatMap { ["-destination", $0] } + ["test"]
        ))
    }

    /// The state of each clause of the first `#if` in `code`: `true` when the build surely leaves
    /// the clause out.
    private func inactiveClauses(_ code: String, on platform: TargetPlatform) throws -> [Bool] {
        let ifConfig = try XCTUnwrap(
            Parser.parse(source: code).statements.first?.item.as(IfConfigDeclSyntax.self)
        )
        return ifConfig.clauses.map(platform.isInactive)
    }

    // MARK: - Platform of the test command

    func test_xcodebuildDestinations() {
        XCTAssertEqual(xcodebuild("platform=iOS Simulator,name=iPhone 16"), iOSSimulator)
        XCTAssertEqual(xcodebuild("generic/platform=iOS Simulator"), iOSSimulator)
        XCTAssertEqual(xcodebuild("generic/platform=iOS"), iOSDevice)
        XCTAssertEqual(xcodebuild("platform=macOS"), macOS)
        XCTAssertEqual(xcodebuild("platform=tvOS Simulator,name=Apple TV"), TargetPlatform(os: .tvOS, isSimulator: true))
    }

    func test_xcodebuildWithoutOneClearPlatformIsUnknown() {
        XCTAssertNil(xcodebuild())
        XCTAssertNil(xcodebuild("platform=macOS,variant=Mac Catalyst"))
        XCTAssertNil(xcodebuild("platform=macOS,variant=Designed for iPad"))
        XCTAssertNil(xcodebuild("platform=watchOS Simulator,name=Apple Watch"))
        XCTAssertNil(xcodebuild("platform=macOS", "platform=iOS Simulator,name=iPhone 16"))
    }

    func test_swiftBuildsForTheHostUnlessItCrossCompiles() {
        #if os(macOS)
        XCTAssertEqual(TargetPlatform(configuration: MuterConfiguration(executable: "/usr/bin/swift", arguments: ["test"])), macOS)
        #endif
        XCTAssertNil(TargetPlatform(configuration: MuterConfiguration(
            executable: "/usr/bin/swift",
            arguments: ["test", "--swift-sdk", "x86_64-swift-linux-musl"]
        )))
        XCTAssertNil(TargetPlatform(configuration: MuterConfiguration(executable: "/usr/bin/make", arguments: ["test"])))
        XCTAssertNil(TargetPlatform(configuration: MuterConfiguration(
            executable: "./scripts/test.sh",
            arguments: ["test"],
            buildSystem: .swift
        )))
    }

    // MARK: - Clauses

    func test_uiKitOnlyFileIsLeftOutOnMacOS() throws {
        let code = """
        #if canImport(UIKit) && !os(watchOS)
        func f() {}
        #endif
        """

        XCTAssertEqual(try inactiveClauses(code, on: macOS), [true])
        XCTAssertEqual(try inactiveClauses(code, on: iOSSimulator), [false])
    }

    func test_elseClauses() throws {
        let code = """
        #if os(iOS)
        func f() {}
        #elseif os(macOS)
        func g() {}
        #else
        func h() {}
        #endif
        """

        XCTAssertEqual(try inactiveClauses(code, on: macOS), [true, false, true])
        XCTAssertEqual(try inactiveClauses(code, on: iOSDevice), [false, true, true])
    }

    /// A custom flag is unknown, so its clause and the ones after it may be active.
    func test_unknownConditionsKeepTheCode() throws {
        XCTAssertEqual(try inactiveClauses("#if DEBUG\n#else\n#endif", on: macOS), [false, false])
        XCTAssertEqual(try inactiveClauses("#if canImport(MyLibrary)\n#endif", on: macOS), [false])
        XCTAssertEqual(try inactiveClauses("#if swift(>=5.9)\n#endif", on: macOS), [false])
        XCTAssertEqual(try inactiveClauses("#if DEBUG\n#elseif os(iOS)\n#else\n#endif", on: macOS), [false, true, false])
    }

    /// `false && unknown` is `false`, and `true || unknown` is `true`.
    func test_threeValuedLogic() throws {
        XCTAssertEqual(try inactiveClauses("#if canImport(UIKit) && DEBUG\n#endif", on: macOS), [true])
        XCTAssertEqual(try inactiveClauses("#if canImport(UIKit) || DEBUG\n#endif", on: macOS), [false])
        XCTAssertEqual(try inactiveClauses("#if os(macOS) || DEBUG\n#else\n#endif", on: macOS), [false, true])
        XCTAssertEqual(try inactiveClauses("#if !(os(Linux))\n#endif", on: macOS), [false])
    }

    /// Linux can use musl instead of Glibc, so `canImport(Glibc)` is known only on Apple platforms.
    func test_glibcIsUnknownOnLinux() throws {
        let code = "#if canImport(Glibc)\n#else\n#endif"

        XCTAssertEqual(try inactiveClauses(code, on: macOS), [true, false])
        XCTAssertEqual(try inactiveClauses(code, on: TargetPlatform(os: .linux, isSimulator: false)), [false, false])
    }

    func test_simulatorEnvironment() throws {
        let code = "#if targetEnvironment(simulator)\n#else\n#endif"

        XCTAssertEqual(try inactiveClauses(code, on: iOSSimulator), [false, true])
        XCTAssertEqual(try inactiveClauses(code, on: iOSDevice), [true, false])
    }

    // MARK: - Discovery

    /// Muter does not mutate code that the test build leaves out: no test could kill such a mutant.
    func test_visitorSkipsCodeThatTheBuildLeavesOut() throws {
        let source = try sourceCode("""
        #if canImport(UIKit)
        func onlyOnIOS(a: Int, b: Int) -> Bool {
            return a > b
        }
        #endif

        func everywhere(a: Int, b: Int) -> Bool {
            return a < b
        }
        """)
        let info = SourceCodeInfo(path: "/path/to/file.swift", code: source)

        let macOSVisitor = MutationOperator.Id.ror.visitor(
            MuterConfiguration(executable: "/usr/bin/xcodebuild", arguments: ["-destination", "platform=macOS", "test"]),
            info,
            []
        )
        macOSVisitor.walk(source)
        let iOSVisitor = MutationOperator.Id.ror.visitor(
            MuterConfiguration(executable: "/usr/bin/xcodebuild", arguments: ["-destination", "platform=iOS Simulator,name=iPhone 16", "test"]),
            info,
            []
        )
        iOSVisitor.walk(source)

        XCTAssertEqual(macOSVisitor.schemataMappings.mutationSchemata.map(\.snapshot.before), ["<"])
        XCTAssertEqual(iOSVisitor.schemataMappings.mutationSchemata.map(\.snapshot.before).sorted(), ["<", ">"])
    }
}
