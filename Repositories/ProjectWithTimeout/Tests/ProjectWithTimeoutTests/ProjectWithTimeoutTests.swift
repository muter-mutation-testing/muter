import Testing
@testable import ProjectWithTimeout

@Test func example() async throws {
    try await Task.sleep(nanoseconds: UInt64(2_000_000_000))
    #expect(foo(value: 1) == 0)
}
