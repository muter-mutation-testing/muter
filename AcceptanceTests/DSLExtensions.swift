import Quick
import Nimble
import Difference

func they(_ description: String, flags: FilterFlags = [:], closure: @escaping () -> Void) {
    it("they " + description, flags: flags, closure: closure)
}

func fthey(_ description: String, flags: FilterFlags = [:], closure: @escaping () -> Void) {
    fit(description, flags: flags, closure: closure)
}

func when(_ description: String, flags: FilterFlags = [:], closure: () -> Void) {
    context("when " + description, flags: flags, closure: closure)
}

func equalDiff<T: Equatable>(_ expectedValue: T?) -> Predicate<T> {
    return Predicate.define { actualExpression in
        let receivedValue = try actualExpression.evaluate()

        if receivedValue == nil {
            var message = ExpectationMessage.fail("")
            if let expectedValue = expectedValue {
                message = ExpectationMessage.expectedCustomValueTo("equal <\(expectedValue)>", "nil")
            }
            return PredicateResult(status: .fail, message: message)
        }
        if expectedValue == nil {
            return PredicateResult(status: .fail, message: ExpectationMessage.fail("").appendedBeNilHint())
        }

        return PredicateResult(bool: receivedValue == expectedValue, message: ExpectationMessage.fail("Found difference for " + diff(expectedValue, receivedValue).joined(separator: ", ")))
    }
}
