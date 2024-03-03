import Foundation

struct SaveProjectMappings: RunCommandStep {
    func run(with state: AnyRunCommandState) async throws -> [RunCommandState.Change] {
        let proj = ProjectSchemataMappings(
            mutatedProjectPath: state.mutatedProjectDirectoryURL.path,
            allMappings: state.mutationMapping
        )

        let encode = try JSONEncoder().encode(proj)
        let jsonUrl = state.projectDirectoryURL
            .appendingPathComponent("muter-mappings")
            .appendingPathExtension("json")

        try encode.write(to: jsonUrl)

        // TODO: move to logger
        print("\nProject mutations saved on: \(FileManager.default.currentDirectoryPath)")

        return []
    }
}
