// swiftformat:disable all
// swiftlint:disable all

import Foundation

#if os(iOS) || os(tvOS)
    print("please ignore me")
#endif

struct ConditionalOperators {
    func something(_ a: Int) -> String { if ProcessInfo.processInfo.environment["sampleWithAllOperators_7_19_223"] != nil {
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
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_18_43_444"] != nil {
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
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_18_18_419"] != nil {
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
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_14_14_356"] != nil {
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
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_12_19_338"] != nil {
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
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_11_19_316"] != nil {
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
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_10_19_292"] != nil {
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
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_9_19_269"] != nil {
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
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_8_19_246"] != nil {
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

    func baz() { if ProcessInfo.processInfo.environment["sampleWithAllOperators_26_37_577"] != nil {
} else {
return _ = foo(bar: { $0 == char })
}
    }
}

struct LogicalConnectors {
    func someCode() -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_32_22_665"] != nil {
        return false || false
} else {
        return false && false
}
    }

    func someOtherCode() -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_36_21_736"] != nil {
        return true && true
} else {
        return true || true
}
    }
}

struct SideEffects {
    func containsSideEffect() -> Int { if ProcessInfo.processInfo.environment["sampleWithAllOperators_42_31_843"] != nil {
        return 1
} else {
        _ = causesSideEffect()
        return 1
}
    }

    func containsSideEffect() -> Int { if ProcessInfo.processInfo.environment["sampleWithAllOperators_49_31_965"] != nil {
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

    func causesAnotherSideEffect() { if ProcessInfo.processInfo.environment["sampleWithAllOperators_60_66_1237"] != nil {
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

    func containsAVoidFunctionCallThatSpansManyLine() { if ProcessInfo.processInfo.environment["sampleWithAllOperators_79_10_1778"] != nil {
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

    private func semaphoreLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_92_16_2140"] != nil {
        defer { semaphore.signal() }
        semaphore.wait()
} else {
        defer { semaphore.signal() }
        semaphore.wait()
        block()
}
    }

    private func recursiveLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_98_16_2267"] != nil {
        defer { lock.unlock() }
        lock.lock()
} else {
        defer { lock.unlock() }
        lock.lock()
        block()
}
    }

    private func nsCondition(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_104_16_2402"] != nil {
        defer { condition.signal() }
        condition.wait()
} else {
        defer { condition.signal() }
        condition.wait()
        block()
}
    }

    private func nsConditionLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_110_16_2581"] != nil {
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
    func someCode(_ a: Bool) -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_125_32_2896"] != nil {
        return a ? false : true
} else {
        return a ? true : false
}
    }

    func someAnotherCode(_ a: Bool) -> String { if ProcessInfo.processInfo.environment["sampleWithAllOperators_129_36_2987"] != nil {
        return a ? "false" : "true"
} else {
        return a ? "true" : "false"
}
    }

    func someCode(_ a: Bool, _ b: Bool) -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_133_44_3088"] != nil {
        return a ? false : b ? true : false
} else if ProcessInfo.processInfo.environment["sampleWithAllOperators_133_37_3081"] != nil {
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
        case let .b(value): if ProcessInfo.processInfo.environment["sampleWithAllOperators_146_26_3347"] != nil {
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
                guard let (_, newRemainder) = doSomething(condition: {  if ProcessInfo.processInfo.environment["sampleWithAllOperators_159_75_3675"] != nil { 
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
