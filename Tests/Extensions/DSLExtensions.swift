import Quick
import Nimble
import Difference

public func they(
    _ description: String,
    file: StaticString = #filePath,
    line: UInt = #line,
    closure: @escaping () -> Void
) {
    it("they " + description, file: file, line: line, closure: closure)
}

public func fthey(
    _ description: String,
    file: StaticString = #filePath,
    line: UInt = #line,
    closure: @escaping () -> Void
) {
    fit(description, file: file, line: line, closure: closure)
}

public func when(
    _ description: String,
    closure: () -> Void
) {
    context("when " + description, closure: closure)
}

// via https://github.com/krzysztofzablocki/Difference#integrate-with-quick
public func equalWithDiff<T: Equatable>(_ expectedValue: T?) -> Predicate<T> {
    return Predicate.define { actualExpression in
        let receivedValue = try actualExpression.evaluate()

        if receivedValue == nil {
            var message = ExpectationMessage.fail("")
            if let expectedValue = expectedValue {
                message = ExpectationMessage.expectedCustomValueTo("equal <\(expectedValue)>", actual: "nil")
            }
            return PredicateResult(status: .fail, message: message)
        }
        if expectedValue == nil {
            return PredicateResult(status: .fail, message: ExpectationMessage.fail("").appendedBeNilHint())
        }

        return PredicateResult(bool: receivedValue == expectedValue, message: ExpectationMessage.fail("Found difference for " + diff(expectedValue, receivedValue).joined(separator: ", ")))
    }
}
