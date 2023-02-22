import XCTest

@testable import muterCore

final class RewriterTests: MuterTestCase {
    private lazy var path = "\(fixturesDirectory)/MutationExamples/sampleWithAllOperators.swift"

    override func setUpWithError() throws {
        try super.setUpWithError()

        FileManager.default.createFile(
            atPath: path,
            contents: sourceCode.data(using: .utf8)
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        try FileManager.default.removeItem(atPath: path)
    }

    func test_allOperatorsWithImplicitReturn() throws {
        let code = try XCTUnwrap(PrepareSourceCode().prepareSourceCode(path))

        let all: [SchemataMutationMapping] = MutationOperator.Id.allCases.accumulate(into: []) { newSchemataMappings, mutationOperatorId in
            let visitor = mutationOperatorId.visitor(
                .init(),
                code.source.asSourceFileInfo
            )

            visitor.sourceCodePreparationChange = code.changes

            visitor.walk(code.source.code)

            let schemataMapping = visitor.schemataMappings

            if !schemataMapping.isEmpty {
                return newSchemataMappings + [schemataMapping]
            } else {
                return newSchemataMappings
            }
        }.mergeByFileName()

        XCTAssertEqual(all.count, 1)

        let mapping = try XCTUnwrap(all.first)

        let sut = MuterRewriter(mapping)

        let mutatedSourceCode = sut.visit(code.source.code).description

        let positions = mapping.mutationSchemata
            .map { ($0.mutationOperatorId, $0.position) }
            .map(OperatorIdAndPositionAssert.init)

        XCTAssertEqual(
            positions,
            [
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 2320,
                        line: 103,
                        column: 16
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 2455,
                        line: 109,
                        column: 16
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 2634,
                        line: 115,
                        column: 16
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 276,
                        line: 12,
                        column: 19
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ternaryOperator,
                    position: MutationPosition(
                        utf8Offset: 2949,
                        line: 130,
                        column: 32
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ternaryOperator,
                    position: MutationPosition(
                        utf8Offset: 3040,
                        line: 134,
                        column: 36
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ternaryOperator,
                    position: MutationPosition(
                        utf8Offset: 3134,
                        line: 138,
                        column: 37
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ternaryOperator,
                    position: MutationPosition(
                        utf8Offset: 3141,
                        line: 138,
                        column: 44
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 299,
                        line: 13,
                        column: 19
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 322,
                        line: 14,
                        column: 19
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 3400,
                        line: 151,
                        column: 26
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 345,
                        line: 15,
                        column: 19
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 3728,
                        line: 164,
                        column: 75
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 369,
                        line: 16,
                        column: 19
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 391,
                        line: 17,
                        column: 19
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 409,
                        line: 19,
                        column: 14
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 472,
                        line: 23,
                        column: 18
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ternaryOperator,
                    position: MutationPosition(
                        utf8Offset: 497,
                        line: 23,
                        column: 43
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .ror,
                    position: MutationPosition(
                        utf8Offset: 620,
                        line: 31,
                        column: 27
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 630,
                        line: 31,
                        column: 37
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .logicalOperator,
                    position: MutationPosition(
                        utf8Offset: 718,
                        line: 37,
                        column: 22
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .logicalOperator,
                    position: MutationPosition(
                        utf8Offset: 789,
                        line: 41,
                        column: 21
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 896,
                        line: 47,
                        column: 31
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 1018,
                        line: 54,
                        column: 31
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 1290,
                        line: 65,
                        column: 66
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 1831,
                        line: 84,
                        column: 10
                    )
                ),
                OperatorIdAndPositionAssert(
                    id: .removeSideEffects,
                    position: MutationPosition(
                        utf8Offset: 2193,
                        line: 97,
                        column: 16
                    )
                )
            ]
        )

        XCTAssertEqual(
            mutatedSourceCode,
            """
            // swiftformat:disable all
            // swiftlint:disable all

            // swiftformat:disable all
            // swiftlint:disable all

            import Foundation

            #if os(iOS) || os(tvOS)
                print("please ignore me")
            #endif

            struct ConditionalOperators {
                func something(_ a: Int) -> String { if ProcessInfo.processInfo.environment["sampleWithAllOperators_12_19_276"] != nil {
                    let b = a != 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_23_43_497"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "what" : "goodbye"
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_23_18_472"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a != 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_19_14_409"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a != 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_17_19_391"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a < 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_16_19_369"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a > 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_15_19_345"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a >= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_14_19_322"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a <= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_13_19_299"] != nil {
                    let b = a == 5
                    let e = a == 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else {
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
                }

                func < (_: String, _: String) -> Bool {
                    return false
                }

                func baz() { if ProcessInfo.processInfo.environment["sampleWithAllOperators_31_37_630"] != nil {
            } else {
            return _ = foo(bar: { $0 == char })
            }
                }
            }

            struct LogicalConnectors {
                func someCode() -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_37_22_718"] != nil {
                    return false || false
            } else {
                    return false && false
            }
                }

                func someOtherCode() -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_41_21_789"] != nil {
                    return true && true
            } else {
                    return true || true
            }
                }
            }

            struct SideEffects {
                func containsSideEffect() -> Int { if ProcessInfo.processInfo.environment["sampleWithAllOperators_47_31_896"] != nil {
                    return 1
            } else {
                    _ = causesSideEffect()
                    return 1
            }
                }

                func containsSideEffect() -> Int { if ProcessInfo.processInfo.environment["sampleWithAllOperators_54_31_1018"] != nil {
                    print("something")
            } else {
                    print("something")

                    _ = causesSideEffect()
            }
                }

                @discardableResult
                func causesSideEffect() -> Int {
                    return 0
                }

                func causesAnotherSideEffect() { if ProcessInfo.processInfo.environment["sampleWithAllOperators_65_66_1290"] != nil {
                    let key = "some key"
                    let value = aFunctionThatReturnsAValue()
            } else {
                    let key = "some key"
                    let value = aFunctionThatReturnsAValue()
                    someFunctionThatWritesToADatabase(key: key, value: value)
            }
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

                func containsAVoidFunctionCallThatSpansManyLine() { if ProcessInfo.processInfo.environment["sampleWithAllOperators_84_10_1831"] != nil {
            } else {
            return functionCall(
                        "some argument",
                        anArgumentLabel: "some argument that's different",
                        anotherArgumentLabel: 5
                    )
            }
                }
            }

            struct Concurrency {
                private let semaphore = DispatchSemaphore(value: 1)
                private let conditionLock = NSConditionLock(condition: 0)
                private let lock = NSRecursiveLock()
                private let condition = NSCondition()

                private func semaphoreLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_97_16_2193"] != nil {
                    defer { semaphore.signal() }
                    semaphore.wait()
            } else {
                    defer { semaphore.signal() }
                    semaphore.wait()
                    block()
            }
                }

                private func recursiveLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_103_16_2320"] != nil {
                    defer { lock.unlock() }
                    lock.lock()
            } else {
                    defer { lock.unlock() }
                    lock.lock()
                    block()
            }
                }

                private func nsCondition(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_109_16_2455"] != nil {
                    defer { condition.signal() }
                    condition.wait()
            } else {
                    defer { condition.signal() }
                    condition.wait()
                    block()
            }
                }

                private func nsConditionLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_115_16_2634"] != nil {
                    defer { conditionLock.unlock(withCondition: 1) }
                    conditionLock.lock(whenCondition: 1)
            } else {
                    defer { conditionLock.unlock(withCondition: 1) }
                    conditionLock.lock(whenCondition: 1)
                    block()
            }
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
                func someCode(_ a: Bool) -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_130_32_2949"] != nil {
                    return a ? false : true
            } else {
                    return a ? true : false
            }
                }

                func someAnotherCode(_ a: Bool) -> String { if ProcessInfo.processInfo.environment["sampleWithAllOperators_134_36_3040"] != nil {
                    return a ? "false" : "true"
            } else {
                    return a ? "true" : "false"
            }
                }

                func someCode(_ a: Bool, _ b: Bool) -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_138_44_3141"] != nil {
                    return a ? false : b ? true : false
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_138_37_3134"] != nil {
                    return a ? b ? false : true: false
            } else {
                    return a ? b ? true : false : false
            }
                }
            }

            public enum Enum {
                case a(CGFloat)
                case b(CGFloat)

                public func kerning(for something: String?) -> CGFloat {
                    switch self {
                    case let .a(value):
                        return value
                    case let .b(value): if ProcessInfo.processInfo.environment["sampleWithAllOperators_151_26_3400"] != nil {
                        if something != nil {
                            return 0
                        }
                        return 10
            } else {
                        if something == nil {
                            return 0
                        }
                        return 10
            }
                    }
                }
            }

            extension String {
                private func bar() -> (String, String) {
                    return Something { value in
                        var remainder = value
                        for char in self {
                            guard let (_, newRemainder) = doSomething(condition: {  if ProcessInfo.processInfo.environment["sampleWithAllOperators_164_75_3728"] != nil { 
            return $0 != char
            } else { 
            return $0 == char
            }}) else {
                                return nil
                            }

                            remainder = newRemainder
                        }
                        return (self, remainder)
                    }
                }
            }

            """
        )
    }
}

private let sourceCode =
    """
    // swiftformat:disable all
    // swiftlint:disable all

    import Foundation

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
