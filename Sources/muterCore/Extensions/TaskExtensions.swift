import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds duration: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(duration) * 1_000_000_000)
    }
}
