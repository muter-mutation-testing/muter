import XCTest

@testable import muterCore

final class MutationSchemataRewriterTests: XCTestCase {
    private lazy var path = "\(fixturesDirectory)/sampleWithAllOperators.swift"
    
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
        let code = try XCTUnwrap(prepareSourceCode(path))

        let all: [SchemataMutationMapping] = MutationOperator.Id.allCases.accumulate(into: []) { newSchemataMappings, mutationOperatorId in
            let visitor = mutationOperatorId.schemataVisitor(
                .init(),
                code.source.asSourceFileInfo
            )
            
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
        
        let sut = MutationSchemataRewriter(mapping)
        
        let mutatedSourceCode = sut.visit(code.source.code).description
        
        XCTAssertEqual(
            mutatedSourceCode,
            """
            // swiftformat:disable all
            // swiftlint:disable all

            import Foundation

            #if os(iOS) || os(tvOS)
              print("please ignore me")
            #endif

            struct ConditionalOperators {
              func something(_ a: Int) -> String { if ProcessInfo.processInfo.environment["sampleWithAllOperators_12_15_215"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_23_39_398"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_23_14_373"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_19_10_324"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_17_15_310"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_16_15_292"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_15_15_272"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_14_15_253"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_13_15_234"] != nil {
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

              func < (lhs: String, rhs: String) -> Bool {
                return false
              }
            }

            struct LogicalConnectors {
              func someCode() -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_33_18_546"] != nil {
                return false || false
            } else {
                return false && false
            }
              }

              func someOtherCode() -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_37_17_609"] != nil {
                return true && true
            } else {
                return true || true
            }
              }

            }

            struct SideEffects {
              func containsSideEffect() -> Int { if ProcessInfo.processInfo.environment["sampleWithAllOperators_44_27_709"] != nil {
                return 1
            } else {
                _ = causesSideEffect()
                return 1
            }
              }

              func containsSideEffect() -> Int { if ProcessInfo.processInfo.environment["sampleWithAllOperators_51_27_815"] != nil {
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

              func causesAnotherSideEffect() { if ProcessInfo.processInfo.environment["sampleWithAllOperators_62_62_1061"] != nil {
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

              func containsAVoidFunctionCallThatSpansManyLine() { if ProcessInfo.processInfo.environment["sampleWithAllOperators_80_31_1539"] != nil {
            } else {
            return functionCall(
                  "some argument",
                  anArgumentLabel: "some argument that's different",
                  anotherArgumentLabel: 5)
            }
              }
            }

            struct Concurrency {
              private let semaphore = DispatchSemaphore(value: 1)
              private let conditionLock = NSConditionLock(condition: 0)
              private let lock = NSRecursiveLock()
              private let condition = NSCondition()

              private func semaphoreLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_93_12_1877"] != nil {
                defer { semaphore.signal() }
                semaphore.wait()
            } else {
                defer { semaphore.signal() }
                semaphore.wait()
                block()
            }
              }

              private func recursiveLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_99_12_1988"] != nil {
                defer { lock.unlock() }
                lock.lock()
            } else {
                defer { lock.unlock() }
                lock.lock()
                block()
            }
              }

              private func nsCondition(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_105_12_2107"] != nil {
                defer { condition.signal() }
                condition.wait()
            } else {
                defer { condition.signal() }
                condition.wait()
                block()
            }
              }

              private func nsConditionLock(block: () -> Void) { if ProcessInfo.processInfo.environment["sampleWithAllOperators_111_12_2270"] != nil {
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

              func someCode(_ a: Bool) -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_127_28_2554"] != nil {
                return a ? false : true
            } else {
                return a ? true : false
            }
              }

              func someAnotherCode(_ a: Bool) -> String { if ProcessInfo.processInfo.environment["sampleWithAllOperators_131_32_2637"] != nil {
                return a ? "false" : "true"
            } else {
                return a ? "true" : "false"
            }
              }

              func someCode(_ a: Bool, _ b: Bool) -> Bool { if ProcessInfo.processInfo.environment["sampleWithAllOperators_135_40_2730"] != nil {
                return a ? false : b ? true : false
            } else if ProcessInfo.processInfo.environment["sampleWithAllOperators_135_33_2723"] != nil {
                return a ? b ? false : true: false
            } else {
                return a ? b ? true : false : false
            }
              }
            }
            """
        )
        
    }
}

private let sourceCode =
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

  func < (lhs: String, rhs: String) -> Bool {
    return false
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
      anotherArgumentLabel: 5)
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
"""
