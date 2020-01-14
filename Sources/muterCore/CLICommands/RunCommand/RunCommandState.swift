import SwiftSyntax
import Foundation

protocol AnyRunCommandState {
    var muterConfiguration: MuterConfiguration { get }
    var projectDirectoryURL: URL { get }
    var tempDirectoryURL: URL { get }
    var sourceFileCandidates: [FilePath] { get }
    var mutationPoints: [MutationPoint] { get }
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] { get }
    var filesToMutate: [String] { get }
    var dryRun: Bool { get }
    var swapFilePathsByOriginalPath: [FilePath: FilePath] { get }
    var mutationTestOutcomes: [MutationTestOutcome] { get }
    
    func apply(_ stateChanges: [RunCommandState.Change])
}

class RunCommandState: AnyRunCommandState {
    var muterConfiguration: MuterConfiguration = .init()
    var projectDirectoryURL: URL = URL(string: "example.com")!
    var tempDirectoryURL: URL = URL(string: "example.com")!
    var sourceFileCandidates: [FilePath] = []
    var mutationPoints: [MutationPoint] = []
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
    var filesToMutate: [String] = []
    var dryRun: Bool = false
    var swapFilePathsByOriginalPath: [FilePath: FilePath] = [:]
    var mutationTestOutcomes: [MutationTestOutcome] = []

    init() { }

    init(from options: RunCommandOptions) {
        self.filesToMutate = options.filesToMutate
        self.dryRun = options.dryRun
    }
}

extension RunCommandState {
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
            case .sourceFileCandidatesDiscovered(let sourceFileCandidates):
                self.sourceFileCandidates = sourceFileCandidates
            case .mutationPointsDiscovered(let mutationPoints):
                self.mutationPoints = mutationPoints
            case .sourceCodeParsed(let sourceCodeByFilePath):
                self.sourceCodeByFilePath = sourceCodeByFilePath
            case .swapFilePathGenerated(let swapFilePathsByOriginalPath):
                self.swapFilePathsByOriginalPath = swapFilePathsByOriginalPath
            case .mutationTestOutcomesGenerated(let mutationTestOutcomes):
                self.mutationTestOutcomes = mutationTestOutcomes
            }
        }
    }
}
