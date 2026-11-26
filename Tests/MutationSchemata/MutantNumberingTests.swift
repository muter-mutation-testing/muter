@testable import muterCore
import XCTest

final class MutantNumberingTests: MuterTestCase {
    private func mapping(_ path: String, lines: [Int]) throws -> SchemataMutationMapping {
        let mapping = SchemataMutationMapping(filePath: path)
        for line in lines {
            try mapping.add(
                sourceCode("return \(line)").statements,
                .make(filePath: path, position: MutationPosition(utf8Offset: line, line: line))
            )
        }
        return mapping
    }

    func test_filesWithTheSameNameKeepTheirOwnMapping() throws {
        let merged = try [
            mapping("/project/A/Utils.swift", lines: [1]),
            mapping("/project/B/Utils.swift", lines: [1]),
            mapping("/project/A/Utils.swift", lines: [2]),
        ].mergeByFilePath()

        let counts = Dictionary(uniqueKeysWithValues: merged.map { ($0.filePath, $0.mutationSchemata.count) })
        XCTAssertEqual(counts, ["/project/A/Utils.swift": 2, "/project/B/Utils.swift": 1])
    }

    func test_mutantsAreNumberedFromOneAcrossFilesInPathOrder() throws {
        let numbered = try [
            mapping("/project/B/Utils.swift", lines: [1]),
            mapping("/project/A/Utils.swift", lines: [5, 1]),
        ].mergeByFilePath().numberedMutants()

        XCTAssertEqual(numbered.map(\.filePath), ["/project/A/Utils.swift", "/project/B/Utils.swift"])
        XCTAssertEqual(numbered.map { $0.mutationSchemata.map(\.position.line) }, [[1, 5], [1]])
        XCTAssertEqual(numbered.map { $0.mutationSchemata.map(\.id) }, [[1, 2], [3]])
    }

    func test_theNumberIsKeptInTheTestPlan() throws {
        let numbered = try [mapping("/project/A/Utils.swift", lines: [1, 2])].numberedMutants()

        let data = try JSONEncoder().encode(numbered)
        let decoded = try JSONDecoder().decode([SchemataMutationMapping].self, from: data)

        XCTAssertEqual(decoded.flatMap(\.mutationSchemata).map(\.id), [1, 2])
    }
}
