import Foundation
import SwiftSyntax

typealias MutationSchemata = [MutationSchema]

final class SchemataMutationMapping: Equatable {
    let filePath: String
    fileprivate var mappings: [CodeBlockItemListSyntax: MutationSchemata]

    var count: Int {
        mappings.count
    }

    var isEmpty: Bool {
        mappings.isEmpty
    }

    var mutationSchemata: MutationSchemata {
        Array(mappings.values).reduce([], +).sorted()
    }

    var codeBlocks: [String] {
        mappings.keys.map(\.description).sorted()
    }

    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }

    convenience init(
        filePath: String = ""
    ) {
        self.init(
            filePath: filePath,
            mappings: [:]
        )
    }

    fileprivate init(
        filePath: String = "",
        mappings: [CodeBlockItemListSyntax: MutationSchemata]
    ) {
        self.filePath = filePath
        self.mappings = mappings
    }

    func add(
        _ codeBlockSyntax: CodeBlockItemListSyntax,
        _ schemata: MutationSchema
    ) {
        mappings[codeBlockSyntax, default: []].append(schemata)
    }

    func add(
        _ codeBlockSyntax: CodeBlockItemListSyntax,
        _ schemata: MutationSchemata
    ) {
        mappings[codeBlockSyntax, default: []].append(contentsOf: schemata)
    }

    func schemata(
        _ codeBlockSyntax: CodeBlockItemListSyntax
    ) -> MutationSchemata? {
        mappings[codeBlockSyntax]
    }
}

func + (
    lhs: SchemataMutationMapping,
    rhs: SchemataMutationMapping
) -> SchemataMutationMapping {
    let result = SchemataMutationMapping(
        filePath: lhs.filePath
    )

    let mergedMappgins = lhs.mappings.merging(rhs.mappings) { $0 + $1 }

    mergedMappgins.forEach { codeBlock, schemata in
        result.add(codeBlock, schemata)
    }

    return result
}

func == (
    lhs: SchemataMutationMapping,
    rhs: SchemataMutationMapping
) -> Bool {
    lhs.codeBlocks == rhs.codeBlocks &&
        lhs.mutationSchemata == rhs.mutationSchemata
}

extension [SchemataMutationMapping] {
    func mergeByFileName() -> Self {
        var result = [FileName: SchemataMutationMapping]()

        for map in self {
            if let exists = result[map.fileName] {
                result[map.fileName] = exists + map
            } else {
                result[map.fileName] = map
            }
        }

        return Array(result.values)
    }
}

// Pretty print for testing assertions description
extension SchemataMutationMapping: CustomStringConvertible, CustomDebugStringConvertible {
    var debugDescription: String { description }

    var description: String {
        let description = mappings.reduce(into: "") { accum, pair in
            accum +=
                """
                source: "\(pair.key.scapedDescription)",
                schemata: \(pair.value)
                """
        }
        return """
        SchemataMutationMapping(
            \(description)
        )
        """
    }
}
