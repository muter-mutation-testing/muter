@testable import muterCore
import XCTest

final class SchemataMutationMappingTests: MuterTestCase {
    private lazy var sourceWithSideEffects = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"
    )!

    func test_encoding() throws {
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceCodeInfo: sourceWithSideEffects
        )

        visitor.walk(sourceWithSideEffects.code)

        let actualSchemata = visitor.schemataMappings
        let projectMappings = ProjectSchemataMappings(
            mutatedProjectPath: "/path/to/mutated",
            allMappings: [actualSchemata, actualSchemata]
        )

        let encoder = try JSONEncoder().encode(projectMappings)
        print(NSString(string: String(data: encoder, encoding: .utf8)!))
    }
}
