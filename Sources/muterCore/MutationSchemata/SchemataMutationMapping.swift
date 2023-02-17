import Foundation
import SwiftSyntax

final class SchemataMutationMapping: Equatable {
    var count: Int {
        mappings.count
    }

    var isEmpty: Bool {
        mappings.isEmpty
    }
    
    var codeBlocks: [String] {
        mappings.keys.map(\.description).sorted()
    }
    
    var schematas: [Schemata] {
        Array(mappings.values).reduce([], +).sorted()
    }
    
    var sortedSchematas: [MutationPosition] {
        schematasSortedByKey().map(\.positionInSourceCode)
    }
    
    var fileName: String {
        return URL(fileURLWithPath: filePath).lastPathComponent
    }

    let filePath: String
    
    fileprivate var mappings: [CodeBlockItemListSyntax: [Schemata]]
    
    private var sortedKeys: [CodeBlockItemListSyntax] {
        mappings.keys.sorted(by: { $0.hashValue < $1.hashValue })
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
        mappings: [CodeBlockItemListSyntax: [Schemata]]
    ) {
        self.filePath = filePath
        self.mappings = mappings
    }

    func add(
        _ codeBlockSyntax: CodeBlockItemListSyntax,
        _ schemata: Schemata
    ) {
        mappings[codeBlockSyntax, default: []].append(schemata)
    }
    
    func add(
        _ codeBlockSyntax: CodeBlockItemListSyntax,
        _ schematas: [Schemata]
    ) {
        mappings[codeBlockSyntax, default: []].append(contentsOf: schematas)
    }

    func schematas(
        _ codeBlockSyntax: CodeBlockItemListSyntax
    ) -> [Schemata]? {
        mappings[codeBlockSyntax]
    }
    
    func skipMutations(_ mutationPoints: [MutationPosition]) -> Self {
        for (codeBlock, schematas) in mappings {
            mappings[codeBlock] = schematas.exclude {
                mutationPoints.contains($0.positionInSourceCode)
            }
        }
        
        return self
    }
    
    func mapSchematas(_ transform: (Int, Schemata) -> Schemata) {
        var index = 0
        sortedKeys.forEach { codeBlock in
            mappings[codeBlock] = (mappings[codeBlock] ?? []).map {
                transform(index, $0)
            }
            index += 1
        }
    }
    
    func schematasSortedByKey() -> [Schemata] {
        sortedKeys.reduce(into: []) { partialResult, codeBlock in
            partialResult.append(contentsOf: mappings[codeBlock] ?? [])
        }
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
    
    mergedMappgins.forEach { (codeBlock, schematas) in
        result.add(codeBlock, schematas)
    }
    
    return result
}

func == (
    lhs: SchemataMutationMapping,
    rhs: SchemataMutationMapping
) -> Bool {
    lhs.codeBlocks == rhs.codeBlocks &&
    lhs.schematas == rhs.schematas
}

extension Array where Element == SchemataMutationMapping {
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
        let description = mappings.reduce(into: "") { (accum, pair) in
            accum +=
            """
            source: "\(pair.key.scapedDescription)",
            schematas: \(pair.value)
            """
        }
        return """
        SchemataMutationMapping(
            \(description)
        )
        """
    }
}
