import Foundation
import SwiftSyntax

struct PerformMutationTesting: RunCommandStep {
    private let ioDelegate: MutationTestingIODelegate
    private let notificationCenter: NotificationCenter
    private let buildErrorsThreshold: Int = 5
    private let fileManager = FileManager.default
    
    init(
        ioDelegate: MutationTestingIODelegate = MutationTestingDelegate(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.ioDelegate = ioDelegate
        self.notificationCenter = notificationCenter
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        fileManager.changeCurrentDirectoryPath(state.tempDirectoryURL.path)

        let result = performMutationTesting(using: state)
        switch result {
        case .success(let outcomes):
            let mutationTestOutcome = state.mutationTestOutcome
            mutationTestOutcome.mutations = outcomes
            mutationTestOutcome.coverage = state.projectCoverage
            notificationCenter.post(name: .mutationTestingFinished, object: mutationTestOutcome)
            return .success([.mutationTestOutcomeGenerated(mutationTestOutcome)])
        case .failure(let reason):
            return .failure(reason)
        }
    }
}

private extension PerformMutationTesting {
    func performMutationTesting(using state: AnyRunCommandState) -> Result<[MutationTestOutcome.Mutation], MuterError> {
        notificationCenter.post(name: .mutationTestingStarted, object: nil)

        let initialTime = Date()
        let (testSuiteOutcome, testLog) = ioDelegate.runTestSuite(using: state.muterConfiguration,
                                                                  activeSchemata: nil,
                                                                  savingResultsIntoFileNamed: "baseline run")
        let timeAfterRunningTestSuite = Date()
        let timePerBuildTestCycle = DateInterval(start: initialTime, end: timeAfterRunningTestSuite).duration
        
        guard testSuiteOutcome == .passed else {
            return .failure(.mutationTestingAborted(reason: .baselineTestFailed(log: testLog)))
        }
        
        let mutationLog = MutationTestLog(
            mutationPoint: .none,
            testLog: testLog,
            timePerBuildTestCycle: timePerBuildTestCycle,
            remainingMutationPointsCount: state.mutationPoints.count
        )
        
        notificationCenter.post(name: .newTestLogAvailable, object: mutationLog)
        
        return insertMutants(using: state)
    }
    
    func insertMutants(using state: AnyRunCommandState) -> Result<[MutationTestOutcome.Mutation], MuterError> {
        var outcomes: [MutationTestOutcome.Mutation] = []
        outcomes.reserveCapacity(state.mutationPoints.count)
        var buildErrors = 0

//        fileManager.changeCurrentDirectoryPath(state.projectDirectoryURL.path)

        let projectDebugFolder = fileManager.currentDirectoryPath + "/Debug"

        let buildForTestingOutput = buildForTesting(state.muterConfiguration) ?? ""

        try? fileManager.removeItem(atPath: projectDebugFolder)
        try? fileManager.copyItem(atPath: buildProductsPath(from: buildForTestingOutput), toPath: projectDebugFolder)

        let xcTestRunPath = fileManager.firstAtPath(projectDebugFolder, withExtension: ".xctestrun") ?? ""

        var previousSchemataId = ""

        var config = state.muterConfiguration
        config.xcTestRunCommand = [
            "-xctestrun",
            xcTestRunPath,
            "test-without-building"
        ]

        for mutationPoint in state.mutationPoints {

//            ioDelegate.backupFile(at: mutationPoint.filePath, using: state.swapFilePathsByOriginalPath)

//            try! FileManager.default.removeItem(atPath: mutationPoint.filePath)

            try! mutationPoint.fileSource.description.write(toFile: mutationPoint.filePath, atomically: true, encoding: .utf8)


//            let sourceCode = state.sourceCodeByFilePath[mutationPoint.filePath]!
//            let mutantSnapshot = insertMutant(at: mutationPoint)

            for schemata in mutationPoint.schematas {
                let logFileName = logFileName(forFilePath: NSString(string: mutationPoint.filePath).lastPathComponent, with: schemata)

                try? switchXCTestRunEnvironmentVariable(atPath: xcTestRunPath, activating: schemata.id, deactivating: previousSchemataId)

                let (testSuiteOutcome, testLog) = ioDelegate.runTestSuite(using: config,
                                                                          activeSchemata: schemata,
                                                                          savingResultsIntoFileNamed: logFileName)

                let outcome = MutationTestOutcome.Mutation(
                    testSuiteOutcome: testSuiteOutcome,
                    mutationPoint: mutationPoint,
                    mutationSnapshot: schemata.snapshot,
                    originalProjectDirectoryUrl: state.projectDirectoryURL,
                    tempDirectoryURL: state.tempDirectoryURL
                )

                outcomes.append(outcome)

                let mutationLog = MutationTestLog(
                    mutationPoint: mutationPoint,
                    testLog: testLog,
                    timePerBuildTestCycle: .none,
                    remainingMutationPointsCount: .none
                )

                previousSchemataId = schemata.id

                notificationCenter.post(name: .newMutationTestOutcomeAvailable,
                                        object: outcome)
                notificationCenter.post(name: .newTestLogAvailable, object: mutationLog)

                buildErrors = testSuiteOutcome == .buildError ? (buildErrors + 1) : 0

                if buildErrors >= buildErrorsThreshold {
                    return .failure(.mutationTestingAborted(reason: .tooManyBuildErrors))
                }
            }


//            let (testSuiteOutcome, testLog) = ioDelegate.runTestSuite(using: state.muterConfiguration,
//                                                                      savingResultsIntoFileNamed: logFileName(for: mutationPoint))

//            ioDelegate.restoreFile(at: mutationPoint.filePath, using: state.swapFilePathsByOriginalPath)
            
//            let outcome = MutationTestOutcome.Mutation(
//                testSuiteOutcome: testSuiteOutcome,
//                mutationPoint: mutationPoint,
//                mutationSnapshot: mutantSnapshot,
//                originalProjectDirectoryUrl: state.projectDirectoryURL,
//                tempDirectoryURL: state.tempDirectoryURL
//            )
//            outcomes.append(outcome)
            
//            let mutationLog = MutationTestLog(
//                mutationPoint: mutationPoint,
//                testLog: testLog,
//                timePerBuildTestCycle: .none,
//                remainingMutationPointsCount: .none
//            )
//
//            notificationCenter.post(name: .newMutationTestOutcomeAvailable,
//                                    object: outcome)
//            notificationCenter.post(name: .newTestLogAvailable, object: mutationLog)

        }
        
        return .success(outcomes)
    }
    
    func insertMutant(at mutationPoint: _MutationPoint) {
        try! ioDelegate.writeFile(to: mutationPoint.filePath, contents: mutationPoint.fileSource.description)
    }
    
    func logFileName(forFilePath filePath: FilePath, with schemata: Schemata) -> String {
        return "\(filePath.replacingOccurrences(of: ".swift", with: ""))_\("todo")_\(schemata.positionInSourceCode.line)_\(schemata.positionInSourceCode.column).log"
    }

    // WILL NOT BE HERE OF COURSE

    func buildForTesting(
        _ configuration: MuterConfiguration
    ) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.arguments = Array(configuration.testCommandArguments.dropLast() + ["build-for-testing"])

        return process.execute()
    }

    func buildProductsPath(
        from buildForTestingOutput: String
    ) -> String {
        let buildRequestPath = buildForTestingOutput.firstMatchOf("Build description path: .*(\\n)")?.replacingOccurrences(of: "Build description path: ", with: "").trimmed ?? ""
        let buildRequestJsonPath = buildRequestPath.replacingOccurrences(of: "desc.xcbuild", with: "buildRequest.json")
        let buildRequestFileContent = fileManager.contents(atPath: buildRequestJsonPath) ?? .init()
        let buildRequest = try? JSONDecoder().decode(XCTestBuildRequest.self, from: buildRequestFileContent)

        return buildRequest?.buildProductsPath ?? ""
    }

    func switchXCTestRunEnvironmentVariable(
        atPath path: String,
        activating activeKey: String,
        deactivating desactiveKey: String
    ) throws {
        let plistContents = fileManager.contents(atPath: path) ?? .init()
        guard var xcTestRun = try PropertyListSerialization.propertyList(from: plistContents, format: nil) as? [String: AnyHashable] else {
            throw PlistReadingErrors.cast
        }

        for (key, value) in xcTestRun {
            if var testConfigurations = value as? [String: AnyHashable],
               testConfigurations.keys.contains("EnvironmentVariables"),
               var allEnvironmentVariables = testConfigurations["EnvironmentVariables"] as? [String: AnyHashable] {
                allEnvironmentVariables[activeKey] = "true"
                allEnvironmentVariables[desactiveKey] = nil

                testConfigurations["EnvironmentVariables"] = allEnvironmentVariables

                xcTestRun[key] = testConfigurations
            }
        }

        let newXCTestRun = try PropertyListSerialization.data(fromPropertyList: xcTestRun, format: .xml, options: 0)

        try newXCTestRun.write(to: URL(fileURLWithPath: path))
    }
}

extension Process {
    func execute() -> String {
        standardOutput = Pipe()

        try? run()

        let output = availableData ?? Data()

        waitUntilExit()

        return String(data: output, encoding: .utf8) ?? ""
    }
}

extension FileManager {
    func firstAtPath(_ path: String, withExtension `extension`: String) -> String? {
        try? sortedContentsOfDirectory(atPath: path)?.first { $0.hasSuffix(`extension`) }
    }

    func sortedContentsOfDirectory(atPath path: String) throws -> [String]? {
        var files = try contentsOfDirectory(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )

        try files.sort {
            let lhs = try $0.resourceValues(forKeys: [URLResourceKey.creationDateKey])
            let rhs = try $1.resourceValues(forKeys: [URLResourceKey.creationDateKey])

            if let lhsDate = lhs.allValues.first?.value as? Date,
               let rhsDate = rhs.allValues.first?.value as? Date {

                return lhsDate.compare(rhsDate) == .orderedDescending
            }
            return true
        }
        return files.map(\.path)
    }
}

enum PlistReadingErrors: Error {
    case cast
}

struct XCTestBuildRequest: Codable {
    var buildProductsPath: String {
        parameters.arenaInfo.buildProductsPath
    }

    private let parameters: Parameters
}

extension XCTestBuildRequest {
    struct Parameters: Codable {
        let arenaInfo: ArenaInfo
    }
}

extension XCTestBuildRequest.Parameters {
    struct ArenaInfo: Codable {
        let buildProductsPath: String
    }
}
