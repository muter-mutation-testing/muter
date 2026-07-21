import Foundation
import SwiftSyntax

typealias MutationSchemata = [MutationSchema]

final class SchemataMutationMapping {
    let filePath: String
    fileprivate var mappings: [CodeBlockKey: MutationSchemata]

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
        mappings: [CodeBlockKey: MutationSchemata]
    ) {
        self.filePath = filePath
        self.mappings = mappings
    }

    func add(
        _ codeBlockSyntax: CodeBlockItemListSyntax,
        _ schemata: MutationSchema
    ) {
        let key = CodeBlockKey(codeBlockSyntax)
        mappings[key, default: []].append(schemata)
    }

    func add(
        _ codeBlockSyntax: CodeBlockItemListSyntax,
        _ schemata: MutationSchemata
    ) {
        let key = CodeBlockKey(codeBlockSyntax)
        mappings[key, default: []].append(contentsOf: schemata)
    }

    func schemata(
        _ codeBlockSyntax: CodeBlockItemListSyntax
    ) -> MutationSchemata? {
        let key = CodeBlockKey(codeBlockSyntax)
        return mappings[key]
    }
}

extension SchemataMutationMapping: Codable {
    enum CodingKeys: String, CodingKey {
        case filePath
        case mappings
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let schematas = try container.decode([MutationSchema].self, forKey: .mappings)
        let key = CodeBlockKey(CodeBlockItemListSyntax([]))
        let mappings = [key: schematas]
        let filePath = try container.decode(String.self, forKey: .filePath)

        self.init(
            filePath: filePath,
            mappings: mappings
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(filePath, forKey: .filePath)
        try container.encode(mutationSchemata, forKey: .mappings)
    }
}

extension SchemataMutationMapping: Equatable {
    static func == (
        lhs: SchemataMutationMapping,
        rhs: SchemataMutationMapping
    ) -> Bool {
        lhs.codeBlocks == rhs.codeBlocks &&
            lhs.mutationSchemata == rhs.mutationSchemata
    }
}

func + (
    lhs: SchemataMutationMapping,
    rhs: SchemataMutationMapping
) -> SchemataMutationMapping {
    let result = SchemataMutationMapping(filePath: lhs.filePath)

    let merged = lhs.mappings.merging(rhs.mappings) { $0 + $1 }
    for (key, schemata) in merged {
        result.mappings[key, default: []].append(contentsOf: schemata)
    }

    return result
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
        let description = mappings.keys.sorted(by: { $0.description < $1.description })
            .reduce(into: "") { accum, key in
                accum +=
                    """
                    source: "\(key.description.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(
                        of: "\"",
                        with: "\\\""
                    ))",
                    schemata: \(mappings[key]!)
                    """
            }
        return """
        SchemataMutationMapping(
            \(description)
        )
        """
    }
}
