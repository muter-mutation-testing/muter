import Foundation

final class MutationTestOutcome {
    var mutations: [Mutation]
    var coverage: Coverage
    
    init(
        mutations: [Mutation] = [],
        coverage: Coverage = .null
    ) {
        self.mutations = mutations
        self.coverage = coverage
    }
}

extension MutationTestOutcome: Equatable {
    static func == (
        lhs: MutationTestOutcome,
        rhs: MutationTestOutcome
    ) -> Bool {
        lhs === rhs || (lhs.coverage == rhs.coverage && lhs.mutations == rhs.mutations)
    }
}

extension MutationTestOutcome {
    struct Mutation: Equatable {
        let testSuiteOutcome: TestSuiteOutcome
        let point: MutationPoint
        let snapshot: MutationOperatorSnapshot
        let originalProjectPath: String
        
        init(
            testSuiteOutcome: TestSuiteOutcome,
            mutationPoint: MutationPoint,
            mutationSnapshot: MutationOperatorSnapshot,
            originalProjectDirectoryUrl: URL
        ) {
            self.testSuiteOutcome = testSuiteOutcome
            self.point = mutationPoint
            self.snapshot = mutationSnapshot
            
            let splitTempFilePath = mutationPoint.filePath.split(separator: "/")
            let projectDirectoryName = originalProjectDirectoryUrl.lastPathComponent
            let numberOfDirectoriesToDrop = splitTempFilePath.map(String.init).firstIndex(of: projectDirectoryName) ?? 0
            let pathSuffix = splitTempFilePath.dropFirst(numberOfDirectoriesToDrop).joined(separator: "/")
            
            self.originalProjectPath = originalProjectDirectoryUrl
                .appendingPathComponent(pathSuffix, isDirectory: true)
                .path
        }
    }
}

struct Coverage: Equatable {
    let percent: Int
    let filesWithoutCoverage: [FilePath]
    
    init(
        percent: Int,
        filesWithoutCoverage: [FilePath]
    ) {
        self.percent = percent
        self.filesWithoutCoverage = filesWithoutCoverage
    }
}

extension Coverage {
    static var null: Coverage {
        Coverage(
            percent: -1,
            filesWithoutCoverage: []
        )
    }
}
