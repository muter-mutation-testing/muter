import XCTest
import TestingExtensions

@testable import muterCore

final class MutationTestingDelegateTests: XCTestCase {
    private let fileManager = FileManager.default
    private lazy var outputFolder = fixturesDirectory + "/MutationTestingDelegateTests"
    private lazy var outputFolderURL = URL(fileURLWithPath: outputFolder)
    
    private let sut = MutationTestingDelegate()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try fileManager.createDirectory(
            at: URL(fileURLWithPath: outputFolder),
            withIntermediateDirectories: true
        )
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try fileManager.removeItem(atPath: outputFolder)
    }
    
    func test_testProcessForXcodeBuild() throws {
        let configuration = MuterConfiguration(
            executable: "/tmp/xcodebuild",
            arguments: [
                "-destination",
                "platform=macOS,arch=x86_64,variant=Mac Catalyst"
            ]
        )

        let schemata = try Schemata.make(id: "schemata_id")
        
        let testProcess = try sut.testProcess(
            with: configuration,
            schemata: schemata,
            and: FileHandle()
        )
        
        XCTAssertEqual(testProcess.arguments, [
            "test-without-building",
            "-destination",
            "platform=macOS,arch=x86_64,variant=Mac Catalyst",
            "-xctestrun",
            "muter.xctestrun"
        ])

        XCTAssertEqual(testProcess.executableURL?.path, "/tmp/xcodebuild")
        XCTAssertEqual(testProcess.qualityOfService, .userInitiated)
    }
    
    func test_testProcessForSwiftBuild() throws {
        let configuration = MuterConfiguration(
            executable: "/tmp/swift",
            arguments: ["test"]
        )

        let schemata = try Schemata.make(id: "schemata_id")
        
        let testProcess = try sut.testProcess(
            with: configuration,
            schemata: schemata,
            and: FileHandle()
        )
        
        XCTAssertEqual(testProcess.arguments, ["test", "--skip-build"])
        XCTAssertEqual(testProcess.environment, ["schemata_id": "YES"])
        XCTAssertEqual(testProcess.executableURL?.path, "/tmp/swift")
        XCTAssertEqual(testProcess.qualityOfService, .userInitiated)
    }
    
    func test_whenSchemetaIsNull_thenDontAddToEnvVars() throws {
        let configuration = MuterConfiguration(
            executable: "/tmp/swift",
            arguments: ["test"]
        )

        let schemata = Schemata.null
        
        let testProcess = try sut.testProcess(
            with: configuration,
            schemata: schemata,
            and: FileHandle()
        )

        XCTAssertNil(testProcess.environment)
    }
    
    func test_switchOn() throws {
        let schemata = try Schemata.make(id: "id")
        let testRun = XCTestRun.init()
        
        try sut.switchOn(
            schemata: schemata,
            for: testRun,
            at: outputFolderURL
        )
        
        XCTAssertTrue(
            fileManager.fileExists(
                atPath: outputFolderURL.appendingPathComponent("muter.xctestrun").path
            )
        )
    }
    
    func test_fileHandle() throws {
        let currentDirectoryPath = fileManager.currentDirectoryPath
        fileManager.changeCurrentDirectoryPath(outputFolder)

        let handleAndLogFileUrl = try sut.fileHandle(
            for: "logFileName"
        )

        XCTAssertEqual(handleAndLogFileUrl.logFileUrl.lastPathComponent, "logFileName")
        XCTAssertNotNil(handleAndLogFileUrl.handle)

        fileManager.changeCurrentDirectoryPath(currentDirectoryPath)
    }
}
