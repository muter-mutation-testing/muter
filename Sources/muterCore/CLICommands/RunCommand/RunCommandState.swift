import SwiftSyntax
import Foundation

protocol AnyRunCommandState: AnyObject {
    var muterConfiguration: MuterConfiguration { get }
    var projectDirectoryURL: URL { get }
    var tempDirectoryURL: URL { get }
    var projectXCTestRun: XCTestRun { get }
    var projectCoverage: Coverage { get }
    var sourceFileCandidates: [FilePath] { get }
    var mutationPoints: [MutationPoint] { get }
    var mutationMapping: [SchemataMutationMapping] { get }
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] { get }
    var filesToMutate: [String] { get }
    var swapFilePathsByOriginalPath: [FilePath: FilePath] { get }
    var mutationTestOutcome: MutationTestOutcome { get }
    
    func apply(_ stateChanges: [RunCommandState.Change])
}

final class RunCommandState: AnyRunCommandState {
    var muterConfiguration: MuterConfiguration = .init()
    var projectDirectoryURL: URL = URL(fileURLWithPath: "path")
    var tempDirectoryURL: URL = URL(fileURLWithPath: "path")
    var projectXCTestRun: XCTestRun = .init()
    var projectCoverage: Coverage = .null
    var sourceFileCandidates: [FilePath] = []
    var mutationPoints: [MutationPoint] = []
    var mutationMapping: [SchemataMutationMapping] = []
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
    var filesToMutate: [String] = []
    var swapFilePathsByOriginalPath: [FilePath: FilePath] = [:]
    var mutationTestOutcome: MutationTestOutcome = .init()

    init() { }

    init(from options: RunOptions) {
        self.filesToMutate = options.filesToMutate
            .reduce(into: []) { accum, next in
                accum.append(
                    contentsOf: next.components(separatedBy: ",")
                        .exclude { $0.isEmpty }
                )
            }
    }
}

extension RunCommandState {
    enum Change: Equatable {
        case configurationParsed(MuterConfiguration)
        case projectDirectoryUrlDiscovered(URL)
        case tempDirectoryUrlCreated(URL)
        case projectXCTestRun(XCTestRun)
        case copyToTempDirectoryCompleted
        case projectCoverage(Coverage)
        case sourceFileCandidatesDiscovered([FilePath])
        case mutationPointsDiscovered([MutationPoint])
        case mutationMappingsDiscovered([SchemataMutationMapping])
        case sourceCodeParsed([FilePath: SourceFileSyntax])
        case swapFilePathGenerated([FilePath: FilePath])
        case mutationTestOutcomeGenerated(MutationTestOutcome)
        case removeProjectFromPreviousRunCompleted
        case removeProjectFromPreviousRunSkipped
    }
}

extension RunCommandState {
    func apply(_ stateChanges: [RunCommandState.Change]) {
        for change in stateChanges {
            switch change {
            case .configurationParsed(let configuration):
                self.muterConfiguration = configuration
            case .projectDirectoryUrlDiscovered(let projectDirectoryURL):
                self.projectDirectoryURL = projectDirectoryURL
            case .tempDirectoryUrlCreated(let tempDirectoryURL):
                self.tempDirectoryURL = tempDirectoryURL
            case .projectXCTestRun(let projectXCTestRun):
                self.projectXCTestRun = projectXCTestRun
            case .projectCoverage(let projectCoverage):
                self.projectCoverage = projectCoverage
            case .sourceFileCandidatesDiscovered(let sourceFileCandidates):
                self.sourceFileCandidates = sourceFileCandidates
            case .mutationPointsDiscovered(let mutationPoints):
                self.mutationPoints = mutationPoints
            case .mutationMappingsDiscovered(let mutationMappings):
                self.mutationMapping = mutationMappings
            case .sourceCodeParsed(let sourceCodeByFilePath):
                self.sourceCodeByFilePath = sourceCodeByFilePath
            case .swapFilePathGenerated(let swapFilePathsByOriginalPath):
                self.swapFilePathsByOriginalPath = swapFilePathsByOriginalPath
            case .mutationTestOutcomeGenerated(let mutationTestOutcome):
                self.mutationTestOutcome = mutationTestOutcome
            case .removeProjectFromPreviousRunCompleted,
                 .copyToTempDirectoryCompleted,
                 .removeProjectFromPreviousRunSkipped:
                break
            }
        }
    }
}
