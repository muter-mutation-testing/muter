import Foundation

struct MuterTestPlan: Equatable, Codable {
    let mutatedProjectPath: String
    let projectCoverage: Int
    let mappings: [SchemataMutationMapping]
}
