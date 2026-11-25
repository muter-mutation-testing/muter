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
        columnStart = data[safe: 1] ?? 0
        lineEnd = data[safe: 2] ?? 0
        columnEnd = data[safe: 3] ?? 0
        executionCount = data[safe: 4] ?? 0
    }

    /// Whether `other` lies entirely inside this region. Positions compare by line first and then by
    /// column, so a region on one line never contains code on a later line.
    func contains(_ other: Region) -> Bool {
        (lineStart, columnStart) <= (other.lineStart, other.columnStart)
            && (other.lineEnd, other.columnEnd) <= (lineEnd, columnEnd)
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
