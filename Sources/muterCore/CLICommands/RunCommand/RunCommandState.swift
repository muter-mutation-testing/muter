import SwiftSyntax
import Foundation

protocol AnyRunCommandState: AnyObject {
    var muterConfiguration: MuterConfiguration { get }
    var projectDirectoryURL: URL { get }
    var tempDirectoryURL: URL { get }
    var projectCoverage: Coverage { get }
    var sourceFileCandidates: [FilePath] { get }
    var mutationPoints: [_MutationPoint] { get }
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] { get }
    var filesToMutate: [String] { get }
    var swapFilePathsByOriginalPath: [FilePath: FilePath] { get }
    var mutationTestOutcome: MutationTestOutcome { get }
    
    func apply(_ stateChanges: [RunCommandState.Change])
}

final class RunCommandState: AnyRunCommandState {
    var muterConfiguration: MuterConfiguration = .init()
    var projectDirectoryURL: URL = URL(string: "example.com")!
    var tempDirectoryURL: URL = URL(string: "example.com")!
    var projectCoverage: Coverage = .null
    var sourceFileCandidates: [FilePath] = []
    var mutationPoints: [_MutationPoint] = []
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
        case copyToTempDirectoryCompleted
        case projectCoverage(Coverage)
        case sourceFileCandidatesDiscovered([FilePath])
        case mutationPointsDiscovered([_MutationPoint])
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
            case .projectCoverage(let projectCoverage):
                self.projectCoverage = projectCoverage
            case .sourceFileCandidatesDiscovered(let sourceFileCandidates):
                self.sourceFileCandidates = sourceFileCandidates
            case .mutationPointsDiscovered(let mutationPoints):
                self.mutationPoints = mutationPoints
            case .sourceCodeParsed(let sourceCodeByFilePath):
                self.sourceCodeByFilePath = sourceCodeByFilePath
            case .swapFilePathGenerated(let swapFilePathsByOriginalPath):
                self.swapFilePathsByOriginalPath = swapFilePathsByOriginalPath
            case .mutationTestOutcomeGenerated(let mutationTestOutcome):
                self.mutationTestOutcome = mutationTestOutcome
            case .removeProjectFromPreviousRunCompleted:
                break
            case .copyToTempDirectoryCompleted:
                break
            case .removeProjectFromPreviousRunSkipped:
                break
            }
        }
    }
}
