import Foundation

struct Region: Equatable {
    let lineStart: Int
    let columnStart: Int
    let lineEnd: Int
    let columnEnd: Int
    let executionCount: Int

    init(lineStart: Int, columnStart: Int, lineEnd: Int, columnEnd: Int, executionCount: Int = 0) {
        self.lineStart = lineStart
        self.columnStart = columnStart
        self.lineEnd = lineEnd
        self.columnEnd = columnEnd
        self.executionCount = executionCount
    }
}

extension Region: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let data = try container.decode([Int].self)

        lineStart = data[safe: 0] ?? 0
        columnStart = data[1]
        lineEnd = data[2]
        columnEnd = data[3]
        executionCount = data[4]
    }

    func contains(_ other: Region) -> Bool {
        lineStart <= other.lineEnd
            && columnStart <= other.columnEnd
    }
}

struct Function: Decodable {
    let filenames: [String]
    let regions: [Region]
}

struct LLVMCoverage: Decodable {
    let data: [Data]

    struct Data: Decodable {
        let functions: [Function]
    }
}
