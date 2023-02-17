// swiftformat:disable all
// swiftlint:disable all

// swiftformat:disable all
// swiftlint:disable all

// swiftformat:disable all
// swiftlint:disable all

// swiftformat:disable all
// swiftlint:disable all

// swiftformat:disable all
// swiftlint:disable all

// swiftformat:disable all
// swiftlint:disable all

// swiftformat:disable all
// swiftlint:disable all

import Foundation

struct AllOperators {
    public static let x = character { $0 == "x" }

    func someCode(_ a: Bool) -> Bool {
    a ? false : true
}

func someAnotherCode(_ a: Bool) -> String {
    a ? "true" : "false"
}

    func containsSideEffect() -> Int {
        _ = causesSideEffect()
        return 1
    }

    func containsAnotherSideEffect() -> Int {
        print("something")

        _ = causesSideEffect()
    }

    func containsSideEffectNoReturn() -> Int {
        print("something")
    }

    func containsADeepMethodCall() {
        let containsIgnoredResult = statement.description.contains("_ = ")
        var anotherIgnoredResult = statement.description.contains("_ = ")
    }

    func containsAVoidFunctionCallThatSpansManyLine() {
        functionCall("some argument",
                     anArgumentLabel: "some argument that's different",
                     anotherArgumentLabel: 5)
    }

}