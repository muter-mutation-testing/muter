import XCTest

@testable import muterCore

final class DiscoverSourceFilesTests: XCTestCase {
    private lazy var filesToMutatePath = "\(self.fixturesDirectory)/FilesToMutate"
    private lazy var filsToDiscoverPath = "\(self.fixturesDirectory)/FilesToDiscover"
    private var state = RunCommandState()
    private var fileManager: FileManagerSpy?
    private lazy var sut = DiscoverSourceFiles(
        fileManager: fileManager ?? FileManager.default
    )
    
    func test_discoveredFilesShouldBeSortedAlphabetically() throws {
        state.tempDirectoryURL = URL(
            fileURLWithPath: filsToDiscoverPath,
            isDirectory: true
        )
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(result, [
            .sourceFileCandidatesDiscovered([
                "\(filsToDiscoverPath)/Directory1/file3.swift",
                "\(filsToDiscoverPath)/Directory2/Directory3/file6.swift",
                "\(filsToDiscoverPath)/ExampleApp/ExampleAppCode.swift",
                "\(filsToDiscoverPath)/file1.swift",
                "\(filsToDiscoverPath)/file2.swift",
            ])
        ])
    }
    
    func test_exclusionList() throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "",
            arguments: [],
            excludeList: ["ExampleApp"]
        )
    
        state.tempDirectoryURL = URL(
            fileURLWithPath: filsToDiscoverPath,
            isDirectory: true
        )

        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(result, [
            .sourceFileCandidatesDiscovered([
                "\(filsToDiscoverPath)/Directory1/file3.swift",
                "\(filsToDiscoverPath)/Directory2/Directory3/file6.swift",
                "\(filsToDiscoverPath)/file1.swift",
                "\(filsToDiscoverPath)/file2.swift",
            ])
        ])
    }
    
    func test_exclusionListWithGlobExpression() throws {
        state.tempDirectoryURL = URL(fileURLWithPath: filesToMutatePath, isDirectory: true)
        state.muterConfiguration = MuterConfiguration(
            executable: "",
            arguments: [],
            excludeList: [
                "/Directory2/**/*.swift",
                "file1.swift",
                "/ProjectName/**/*.swift",]
        )
        
        let result = try XCTUnwrap(sut.run(with: state).get())

        XCTAssertEqual(result, [
            .sourceFileCandidatesDiscovered([
                "\(filesToMutatePath)/Directory2/Directory3/file6.swift",
                "\(filesToMutatePath)/ExampleApp/ExampleAppCode.swift",
                "\(filesToMutatePath)/ProjectName/AnotherFolder/Module.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/AppDelegate.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 1.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 2.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 3.swift",
            ])
        ])
    }

    func test_shouldIgnoreFilesWithoutCoverage() throws {
        state.muterConfiguration = MuterConfiguration(executable: "", arguments: [])
        state.tempDirectoryURL = URL(
            fileURLWithPath: filsToDiscoverPath,
            isDirectory: true
        )

        state.projectCoverage = Coverage.make(
            filesWithoutCoverage: [
                "\(filsToDiscoverPath)/ExampleApp/ExampleAppCode.swift",
                "\(filsToDiscoverPath)/Directory2/Directory3/file6.swift",
            ]
        )
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(result, [
            .sourceFileCandidatesDiscovered([
                "\(filsToDiscoverPath)/Directory1/file3.swift",
                "\(filsToDiscoverPath)/file1.swift",
                "\(filsToDiscoverPath)/file2.swift",
            ])
        ])
    }
    
    func test_whenDoesntDiscoverFilesInProjectDirectory() {
        state.tempDirectoryURL = URL(
            fileURLWithPath: "\(filsToDiscoverPath)/Directory4",
            isDirectory: true
        )
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(result, .failure(.noSourceFilesDiscovered))
    }
    
    func test_listOfFilesToMutate() throws {
        let fileManager = FileManagerSpy()
        fileManager.subpathsToReturn = []
    
        state.filesToMutate = [
            "file1.swift",
            "file2.swift",
            "/Directory2/Directory3/file6.swift"
        ]

        state.tempDirectoryURL = URL(fileURLWithPath: filesToMutatePath, isDirectory: true)
        fileManager.fileExistsToReturn = state.filesToMutate.compactMap { _ in true }
        
        sut = DiscoverSourceFiles(fileManager: fileManager)

        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(result, [
            .sourceFileCandidatesDiscovered([
                "\(filesToMutatePath)/Directory2/Directory3/file6.swift",
                "\(filesToMutatePath)/file1.swift",
                "\(filesToMutatePath)/file2.swift",
            ]),
        ])
    }
    
    func test_listOfFileToMutateWithGlobExpression() throws {
        state.filesToMutate = [
            "/Directory2/**/*.swift",
            "file1.swift",
            "/ExampleApp/*.swift"
        ]

        state.tempDirectoryURL = URL(fileURLWithPath: filesToMutatePath, isDirectory: true)

        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(result, [
            .sourceFileCandidatesDiscovered([
                "\(filesToMutatePath)/Directory2/Directory3/file6.swift",
                "\(filesToMutatePath)/ExampleApp/ExampleAppCode.swift",
                "\(filesToMutatePath)/file1.swift",
            ]),
        ])
    }

    func test_listOfFileToMutateWithRelativePaths() throws {
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(filesToMutatePath)

        state.tempDirectoryURL = URL(fileURLWithPath: filesToMutatePath, isDirectory: true)
        state.filesToMutate = [
            "./ProjectName/ProjectName/AppDelegate.swift",
            "../ProjectName/AnotherFolder/Module.swift",
            "./*.swift",
            "./ProjectName/ProjectName/Models/*.swift",
            "./**/*.swift",
        ]
        
        let result = try XCTUnwrap(sut.run(with: state).get())

        XCTAssertEqual(result, [
            .sourceFileCandidatesDiscovered([
                "\(filesToMutatePath)/Directory2/Directory3/file6.swift",
                "\(filesToMutatePath)/Directory5/file1.swift",
                "\(filesToMutatePath)/ExampleApp/ExampleAppCode.swift",
                "\(filesToMutatePath)/ProjectName/AnotherFolder/Module.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/AppDelegate.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/AppDelegate.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 1.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 1.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 2.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 2.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 3.swift",
                "\(filesToMutatePath)/ProjectName/ProjectName/Models/file 3.swift",
                "\(filesToMutatePath)/file1.swift",
            ])
        ])
        
        FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath)
    }

    func test_listOfFileToMutateWithoutGlobExpressions() throws {
        fileManager = FileManagerSpy()
        fileManager!.subpathsToReturn = []

        state.filesToMutate = ["file1.swift", "file2.swift", "/Directory2/Directory3/file6.swift"]
        state.tempDirectoryURL = URL(
            fileURLWithPath: filesToMutatePath,
            isDirectory: true
        )

        fileManager!.fileExistsToReturn = state.filesToMutate.compactMap { _ in true }

        let result = try XCTUnwrap(sut.run(with: state).get())

        XCTAssertEqual(result, [
            .sourceFileCandidatesDiscovered([
                "\(filesToMutatePath)/Directory2/Directory3/file6.swift",
                "\(filesToMutatePath)/file1.swift",
                "\(filesToMutatePath)/file2.swift",
            ])
        ])

        XCTAssertEqual(fileManager?.methodCalls, [
            "fileExists(atPath:)",
            "fileExists(atPath:)",
            "fileExists(atPath:)",
        ])
    }

    func test_fileNotFoundFailure() {
        state.filesToMutate = ["doesntExist.swift"]
        state.tempDirectoryURL = URL(
            fileURLWithPath: filesToMutatePath,
            isDirectory: true
        )

        let result = sut.run(with: state)

        XCTAssertEqual(result, .failure(.noSourceFilesOnExclusiveList))
    }

    func test_noSwiftFileFailure() {
        state.filesToMutate = ["/Directory2/Directory3/file6"]
        state.tempDirectoryURL = URL(
            fileURLWithPath: filesToMutatePath,
            isDirectory: true
        )

        let result = sut.run(with: state)

        XCTAssertEqual(result, .failure(.noSourceFilesOnExclusiveList))
    }
}
