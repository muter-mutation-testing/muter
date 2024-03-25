@testable import muterCore
import SnapshotTesting
import SwiftParser
import TestingExtensions
import XCTest

final class RewriterTests: MuterTestCase {
    private lazy var samplePath = "\(fixturesDirectory)/MutationExamples/sampleWithAllOperators.swift"

    override func setUpWithError() throws {
        try super.setUpWithError()

        FileManager.default.createFile(
            atPath: samplePath,
            contents: allOperatorsSourceCode.data(using: .utf8)
        )
    }

    override func setUp() {
        super.setUp()

        current.writeFile = { try $0.write(toFile: $1, atomically: true, encoding: .utf8) }
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        try FileManager.default.removeItem(atPath: samplePath)
    }

    func test_allOperatorsWithImplicitReturn() throws {
        let sourceCode = try XCTUnwrap(PrepareSourceCode().prepareSourceCode(samplePath))

        let all = generateSchemataMappings(
            for: sourceCode.source,
            changes: sourceCode.changes
        )

        XCTAssertEqual(all.count, 1)

        let mapping = try XCTUnwrap(all.first)

        let positions = mapping.mutationSchemata
            .map { ($0.mutationOperatorId, $0.position) }
            .map(OperatorIdAndPositionAssert.init)

        AssertSnapshot(positions.description)
    }

    func test_allOperatorsWithImplicitReturnSourceCode() throws {
        let sourceCode = try XCTUnwrap(PrepareSourceCode().prepareSourceCode(samplePath))

        let all = generateSchemataMappings(
            for: sourceCode.source,
            changes: sourceCode.changes
        )

        XCTAssertEqual(all.count, 1)

        let mapping = try XCTUnwrap(all.first)

        let sut = MuterRewriter(mapping)

        let mutatedSourceCode = sut.rewrite(sourceCode.source.code).description

        AssertSnapshot(formatCode(mutatedSourceCode.description))
    }
}

private let allOperatorsSourceCode =
    """
    #if os(iOS) || os(tvOS)
        print("please ignore me")
    #endif

    struct ConditionalOperators {
        func something(_ a: Int) -> String {
            let b = a == 5
            let e = a != 1
            let c = a >= 4
            let d = a <= 10
            let f = a < 5
            let g = a > 5

            if a == 10 {
                return "hello"
            }

            return a == 9 ? "goodbye" : "what"
        }

        func < (_: String, _: String) -> Bool {
            return false
        }

        func baz() {
            _ = foo(bar: { $0 == char })
        }
    }

    struct LogicalConnectors {
        func someCode() -> Bool {
            return false && false
        }

        func someOtherCode() -> Bool {
            return true || true
        }
    }

    struct SideEffects {
        func containsSideEffect() -> Int {
            _ = causesSideEffect()
            return 1
        }

        func containsSideEffect() -> Int {
            print("something")

            _ = causesSideEffect()
        }

        @discardableResult
        func causesSideEffect() -> Int {
            return 0
        }

        func causesAnotherSideEffect() {
            let key = "some key"
            let value = aFunctionThatReturnsAValue()
            someFunctionThatWritesToADatabase(key: key, value: value)
        }

        func containsSpecialCases() {
            fatalError("this should never be deleted!")
            exit(1)
            abort()
        }

        func containsADeepMethodCall() {
            let containsIgnoredResult = statement.description.contains("_ = ")
            var anotherIgnoredResult = statement.description.contains("_ = ")
        }

        func containsAVoidFunctionCallThatSpansManyLine() {
            functionCall(
                "some argument",
                anArgumentLabel: "some argument that's different",
                anotherArgumentLabel: 5
            )
        }
    }

    struct Concurrency {
        private let semaphore = DispatchSemaphore(value: 1)
        private let conditionLock = NSConditionLock(condition: 0)
        private let lock = NSRecursiveLock()
        private let condition = NSCondition()

        private func semaphoreLock(block: () -> Void) {
            defer { semaphore.signal() }
            semaphore.wait()
            block()
        }

        private func recursiveLock(block: () -> Void) {
            defer { lock.unlock() }
            lock.lock()
            block()
        }

        private func nsCondition(block: () -> Void) {
            defer { condition.signal() }
            condition.wait()
            block()
        }

        private func nsConditionLock(block: () -> Void) {
            defer { conditionLock.unlock(withCondition: 1) }
            conditionLock.lock(whenCondition: 1)
            block()
        }

        private func sync(block: () -> Int) -> Int {
            let semaphore = DispatchSemaphore(value: 2)
            semaphore.wait()
            let value = block()
            semaphore.signal()

            return value
        }
    }

    struct TernayOperators {
        func someCode(_ a: Bool) -> Bool {
            return a ? true : false
        }

        func someAnotherCode(_ a: Bool) -> String {
            return a ? "true" : "false"
        }

        func someCode(_ a: Bool, _ b: Bool) -> Bool {
            return a ? b ? true : false : false
        }
    }

    public enum Enum {
        case a(CGFloat)
        case b(CGFloat)

        public func kerning(for something: String?) -> CGFloat {
            switch self {
            case let .a(value):
                return value
            case let .b(value):
                if something == nil {
                    return 0
                }
                return 10
            }
        }
    }

    extension String {
        private func bar() -> (String, String) {
            return Something { value in
                var remainder = value
                for char in self {
                    guard let (_, newRemainder) = doSomething(condition: { $0 == char }) else {
                        return nil
                    }

                    remainder = newRemainder
                }
                return (self, remainder)
            }
        }
    }

    """

private struct OperatorIdAndPositionAssert: Equatable {
    let id: MutationOperator.Id
    let position: MutationPosition
}

extension OperatorIdAndPositionAssert: CustomStringConvertible {
    var description: String {
        """
        OperatorIdAndPositionAssert(
            id: .\(id),
            position: MutationPosition(
                utf8Offset: \(position.utf8Offset),
                line: \(position.line),
                column: \(position.column)
            )
        )
        """
    }
}
