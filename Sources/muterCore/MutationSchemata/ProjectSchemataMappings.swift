import Foundation

struct ProjectSchemataMappings: Equatable, Codable {
    let mutatedProjectPath: String
    let allMappings: [SchemataMutationMapping]
}
