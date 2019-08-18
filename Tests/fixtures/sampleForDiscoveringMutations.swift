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

class Baz {
    struct Info {
        func foo() {}
    }
}

class Bar {
    struct Info {
        func foo() {}
    }
}

struct Info {
    func foo() {}
    
    class CustomError: Error {
        func haltAndCatchFire () {} // note the space before the parentheses
        
        enum AnotherLayer {
            case value
            func ofHell(dictionary: [String: Result<(), Never>]) -> ExampleEnum {
                return self
            }
        }

    }
}

extension ItsAlmostLikeItNeverEnds {
    struct DoesIt {
        func endIt() -> Please {}
    }
}
