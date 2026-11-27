import Foundation

struct MuterTestPlan: Equatable, Codable {
    let mutatedProjectPath: String
    let projectCoverage: Int
    let mappings: [SchemataMutationMapping]
    /// The mutants that `muter:disable` comments turned off, so that the reports can show them.
    let ignoredMutants: [IgnoredMutant]

    init(
        mutatedProjectPath: String,
        projectCoverage: Int,
        mappings: [SchemataMutationMapping],
        ignoredMutants: [IgnoredMutant] = []
    ) {
        self.mutatedProjectPath = mutatedProjectPath
        self.projectCoverage = projectCoverage
        self.mappings = mappings
        self.ignoredMutants = ignoredMutants
    }

    /// Test plans written before `ignoredMutants` existed still decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mutatedProjectPath = try container.decode(String.self, forKey: .mutatedProjectPath)
        projectCoverage = try container.decode(Int.self, forKey: .projectCoverage)
        mappings = try container.decode([SchemataMutationMapping].self, forKey: .mappings)
        ignoredMutants = try container.decodeIfPresent([IgnoredMutant].self, forKey: .ignoredMutants) ?? []
    }
}
