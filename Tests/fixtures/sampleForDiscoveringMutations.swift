struct Example2 {
    func areEqualAsString(_ a: Int) -> String {
        let b = a != a
        return b == a ? "equal" : "not equal"
    }
    
    func areEqualAsString(_ a: Float) -> String {
        return ""
    }
}

func areEqualAsString(_ a: Float) -> String {
    return ""
}

class Example {
    func foo(_ a: [Int]) {}
}

func notTheSameThing() {
    return ""
}

enum ExampleEnum {
    case value
    func foo(dictionary: [String: Result<(), Never>]) -> ExampleEnum {
        return self
    }
}

func anotherNotTheSameThing() {
    return ""
}

extension ExampleEnum {
    private func bar() {}
}

func andAnotherNotTheSameThing() {
    return ""
}

protocol SomeProtocol {
    func baz()
    func kangaroo()
}

extension SomeProtocol {
    func kangaroo() {}
}

func thisShouldntBeASurpriseByNow() {
    return ""
}
