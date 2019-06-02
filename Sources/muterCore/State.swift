import SwiftSyntax
import Foundation

protocol AnyRunCommandState {
    var muterConfiguration: MuterConfiguration { get }
    var projectDirectoryURL: URL { get }
    var tempDirectoryURL: URL { get }
    var sourceFileCandidates: [FilePath] { get }
    var mutationPoints: [MutationPoint] { get }
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] { get }
    var swapFilePathsByOriginalPath: [FilePath: FilePath] { get }
    var mutationTestOutcomes: [MutationTestOutcome] { get }
}

class RunCommandState: AnyRunCommandState {
    static let shared = RunCommandState()
    
    var muterConfiguration: MuterConfiguration = .init()
    var projectDirectoryURL: URL = URL(string: "example.com")!
    var tempDirectoryURL: URL = URL(string: "example.com")!
    var sourceFileCandidates: [FilePath] = []
    var mutationPoints: [MutationPoint] = []
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
    var swapFilePathsByOriginalPath: [FilePath: FilePath] = [:]
    var mutationTestOutcomes: [MutationTestOutcome] = []
    
    enum Change: Equatable {
        case configurationParsed(MuterConfiguration)
        case projectDirectoryUrlDiscovered(URL)
        case tempDirectoryUrlCreated(URL)
        case sourceFileCandidatesDiscovered([FilePath])
        case mutationPointsDiscovered([MutationPoint])
        case sourceCodeParsed([FilePath: SourceFileSyntax])
        case swapFilePathGenerated([FilePath: FilePath])
        case mutationTestOutcomesGenerated([MutationTestOutcome])
    }
}

extension RunCommandState.Change {
    func apply(to state: inout RunCommandState) {
        switch self {
        case .configurationParsed(let configuration):
            state.muterConfiguration = configuration
        case .projectDirectoryUrlDiscovered(let projectDirectoryURL):
            state.projectDirectoryURL = projectDirectoryURL
        case .tempDirectoryUrlCreated(let tempDirectoryURL):
            state.tempDirectoryURL = tempDirectoryURL
        case .sourceFileCandidatesDiscovered(let sourceFileCandidates):
            state.sourceFileCandidates = sourceFileCandidates
        case .mutationPointsDiscovered(let mutationPoints):
            state.mutationPoints = mutationPoints
        case .sourceCodeParsed(let sourceCodeByFilePath):
            state.sourceCodeByFilePath = sourceCodeByFilePath
        case .swapFilePathGenerated(let swapFilePathsByOriginalPath):
            state.swapFilePathsByOriginalPath = swapFilePathsByOriginalPath
        case .mutationTestOutcomesGenerated(let mutationTestOutcomes):
            state.mutationTestOutcomes = mutationTestOutcomes
        }
    }
}
