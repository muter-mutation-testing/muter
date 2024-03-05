import Foundation

struct MuterTestPlan: Equatable, Codable {
    let mutatedProjectPath: String
    let allMappings: [SchemataMutationMapping]
}
