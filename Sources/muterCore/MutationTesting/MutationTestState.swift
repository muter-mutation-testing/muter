import Foundation
import SwiftSyntax

protocol AnyMutationTestState: AnyObject {
    var runOptions: Run.Options { get }
    var newVersion: String { get }
    var mutationTestingStartTime: Date { get }
    var muterConfiguration: MuterConfiguration { get }
    var mutationOperatorList: MutationOperatorList { get }
    var projectDirectoryURL: URL { get }
    var mutatedProjectDirectoryURL: URL { get }
    var projectXCTestRun: XCTestRun { get }
    var projectCoverage: Coverage { get }
    var sourceFileCandidates: [FilePath] { get }
    var mutationPoints: [MutationPoint] { get }
    var mutationMapping: [SchemataMutationMapping] { get }
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] { get }
    var filesToMutate: [String] { get }
    var swapFilePathsByOriginalPath: [FilePath: FilePath] { get }
    var mutationTestOutcome: MutationTestOutcome { get }

    func apply(_ stateChanges: [MutationTestState.Change])
}

final class MutationTestState: AnyMutationTestState {
    var runOptions: Run.Options = .null
    var mutationOperatorList: MutationOperatorList = []
    var filesToMutate: [String] = []
    var newVersion: String = ""
    var mutationTestingStartTime: Date = .init()
    var muterConfiguration: MuterConfiguration = .init()
    var projectDirectoryURL: URL = .init(fileURLWithPath: "path")
    var mutatedProjectDirectoryURL: URL = .init(fileURLWithPath: "path")
    var projectXCTestRun: XCTestRun = .init()
    var projectCoverage: Coverage = .null
    var sourceFileCandidates: [FilePath] = []
    var mutationPoints: [MutationPoint] = []
    var mutationMapping: [SchemataMutationMapping] = []
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
    var swapFilePathsByOriginalPath: [FilePath: FilePath] = [:]
    var mutationTestOutcome: MutationTestOutcome = .init()

    init() {}

    init(from options: Run.Options) {
        runOptions = options
        mutationOperatorList = options.mutationOperatorsList
        filesToMutate = options.filesToMutate

        if let testPlan = options.testPlan {
            mutatedProjectDirectoryURL = URL(fileURLWithPath: testPlan.mutatedProjectPath)
            projectCoverage = .init(percent: testPlan.projectCoverage)
            mutationMapping = testPlan.mappings
        }
    }
}

extension MutationTestState {
    enum Change: Equatable {
        case newVersionAvaiable(String)
        case configurationParsed(MuterConfiguration)
        case projectDirectoryUrlDiscovered(URL)
        case tempDirectoryUrlCreated(URL)
        case projectXCTestRun(XCTestRun)
        case projectCoverage(Coverage)
        case sourceFileCandidatesDiscovered([FilePath])
        case mutationPointsDiscovered([MutationPoint])
        case mutationMappingsDiscovered([SchemataMutationMapping])
        case sourceCodeParsed([FilePath: SourceFileSyntax])
        case swapFilePathGenerated([FilePath: FilePath])
        case mutationTestOutcomeGenerated(MutationTestOutcome)
    }
}

extension MutationTestState {
    func apply(_ stateChanges: [MutationTestState.Change]) {
        for change in stateChanges {
            switch change {
            case let .newVersionAvaiable(newVersion):
                self.newVersion = newVersion
            case let .configurationParsed(muterConfiguration):
                self.muterConfiguration = muterConfiguration
            case let .projectDirectoryUrlDiscovered(projectDirectoryURL):
                self.projectDirectoryURL = projectDirectoryURL
            case let .tempDirectoryUrlCreated(mutatedProjectDirectoryURL):
                self.mutatedProjectDirectoryURL = mutatedProjectDirectoryURL
            case let .projectXCTestRun(projectXCTestRun):
                self.projectXCTestRun = projectXCTestRun
            case let .projectCoverage(projectCoverage):
                self.projectCoverage = projectCoverage
            case let .sourceFileCandidatesDiscovered(sourceFileCandidates):
                self.sourceFileCandidates = sourceFileCandidates
            case let .mutationPointsDiscovered(mutationPoints):
                self.mutationPoints = mutationPoints
            case let .mutationMappingsDiscovered(mutationMapping):
                self.mutationMapping = mutationMapping
            case let .sourceCodeParsed(sourceCodeByFilePath):
                self.sourceCodeByFilePath = sourceCodeByFilePath
            case let .swapFilePathGenerated(swapFilePathsByOriginalPath):
                self.swapFilePathsByOriginalPath = swapFilePathsByOriginalPath
            case let .mutationTestOutcomeGenerated(mutationTestOutcome):
                self.mutationTestOutcome = mutationTestOutcome
            }
        }
    }
}
