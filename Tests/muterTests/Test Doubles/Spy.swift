protocol Spy {
    var methodCalls: [String] { get }
}

protocol Dummy {}

enum TestingError: Error {
    case dummyMethodInvoked
}
