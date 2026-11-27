import Foundation
import SwiftOperators
import SwiftSyntax

/// The platform that the test command builds for. Muter uses it to find the `#if` blocks that the
/// test build does not compile: a mutant in such a block can never fail a test, so it would always
/// be reported as survived.
///
/// Muter decides only what it knows for sure. A condition that it cannot evaluate, such as a custom
/// flag (`DEBUG`), `swift(>=5.9)` or `canImport` of a third-party module, counts as maybe active,
/// and Muter mutates the code in it as before.
struct TargetPlatform: Equatable {
    enum OperatingSystem: String, CaseIterable {
        case macOS
        case iOS
        case tvOS
        case watchOS
        case visionOS
        case linux = "Linux"
    }

    let os: OperatingSystem
    let isSimulator: Bool
}

extension TargetPlatform {
    /// The platform of a test command, or `nil` when Muter cannot tell it.
    /// The executable must be `swift` or `xcodebuild` itself: a wrapper script can add arguments,
    /// such as another destination, that Muter does not see.
    init?(configuration: MuterConfiguration) {
        let executable = URL(fileURLWithPath: configuration.testCommandExecutable).lastPathComponent
        switch (configuration.buildSystem, executable) {
        case (.swift, "swift"):
            self.init(swiftArguments: configuration.testCommandArguments)
        case (.xcodebuild, "xcodebuild"):
            self.init(xcodebuildArguments: configuration.testCommandArguments)
        default:
            return nil
        }
    }

    /// `swift test` builds for the machine it runs on, unless the arguments name another target.
    private init?(swiftArguments arguments: [String]) {
        let crossCompiling = ["--triple", "--swift-sdk", "--sdk", "--destination", "--experimental-swift-sdk"]
        guard !arguments.contains(where: { argument in
            crossCompiling.contains { argument == $0 || argument.hasPrefix($0 + "=") }
        }) else {
            return nil
        }

        #if os(macOS)
        self.init(os: .macOS, isSimulator: false)
        #elseif os(Linux)
        self.init(os: .linux, isSimulator: false)
        #else
        return nil
        #endif
    }

    /// `xcodebuild` builds for its `-destination`. With no destination, or destinations for more
    /// than one platform, Muter does not decide.
    private init?(xcodebuildArguments arguments: [String]) {
        let destinations = zip(arguments, arguments.dropFirst())
            .filter { $0.0 == "-destination" }
            .map(\.1)
        let platforms = destinations.map(Self.init(destination:))
        guard let first = platforms.first,
              let platform = first,
              platforms.allSatisfy({ $0 == platform })
        else {
            return nil
        }

        self = platform
    }

    /// A destination such as `platform=iOS Simulator,name=iPhone 16` or `generic/platform=macOS`.
    /// A destination with a variant is left out: `variant=Mac Catalyst` and
    /// `variant=Designed for iPad` run on a Mac but build for iOS. watchOS is left out too: Muter
    /// cannot describe these platforms exactly.
    private init?(destination: String) {
        guard !destination.contains("variant=") else {
            return nil
        }

        let platform = destination
            .components(separatedBy: ",")
            .compactMap { field -> String? in
                let parts = field.components(separatedBy: "=")
                guard parts.count == 2, parts[0].hasSuffix("platform") else {
                    return nil
                }
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
            .first

        switch platform {
        case "macOS", "OS X":
            self.init(os: .macOS, isSimulator: false)
        case "iOS":
            self.init(os: .iOS, isSimulator: false)
        case "iOS Simulator":
            self.init(os: .iOS, isSimulator: true)
        case "tvOS":
            self.init(os: .tvOS, isSimulator: false)
        case "tvOS Simulator":
            self.init(os: .tvOS, isSimulator: true)
        case "visionOS", "xrOS":
            self.init(os: .visionOS, isSimulator: false)
        case "visionOS Simulator", "xrOS Simulator":
            self.init(os: .visionOS, isSimulator: true)
        default:
            return nil
        }
    }
}

extension TargetPlatform {
    /// Tells if the build surely leaves out the code of this `#if`, `#elseif` or `#else` clause.
    func isInactive(_ clause: IfConfigClauseSyntax) -> Bool {
        guard let ifConfig = clause.parent?.parent?.as(IfConfigDeclSyntax.self) else {
            return false
        }

        // The compiler takes the first clause whose condition is true. A clause is surely left out
        // when its own condition is false, or when an earlier condition is surely true.
        var earlierClauseIsActive = false
        for candidate in ifConfig.clauses {
            let isActive = candidate.condition.map(evaluate) ?? true
            if candidate.id == clause.id {
                return earlierClauseIsActive || isActive == false
            }
            if isActive == true {
                earlierClauseIsActive = true
            }
        }

        return false
    }

    /// The value of a condition: `true`, `false`, or `nil` when Muter cannot tell. `&&` and `||` use
    /// three-valued logic, so `canImport(UIKit) && DEBUG` is `false` on macOS.
    func evaluate(_ condition: ExprSyntax) -> Bool? {
        let folded = (try? OperatorTable.standardOperators.foldAll(condition))?.as(ExprSyntax.self) ?? condition
        return value(of: folded)
    }

    private func value(of expression: ExprSyntax) -> Bool? {
        if let literal = expression.as(BooleanLiteralExprSyntax.self) {
            return literal.literal.tokenKind == .keyword(.true)
        }

        if let tuple = expression.as(TupleExprSyntax.self),
           tuple.elements.count == 1,
           let element = tuple.elements.first,
           element.label == nil {
            return value(of: element.expression)
        }

        if let prefix = expression.as(PrefixOperatorExprSyntax.self),
           prefix.operator.text == "!" {
            return value(of: prefix.expression).map(!)
        }

        if let infix = expression.as(InfixOperatorExprSyntax.self),
           let op = infix.operator.as(BinaryOperatorExprSyntax.self)?.operator.text {
            let lhs = value(of: infix.leftOperand)
            let rhs = value(of: infix.rightOperand)
            switch op {
            case "&&":
                if lhs == false || rhs == false { return false }
                if lhs == true, rhs == true { return true }
                return nil
            case "||":
                if lhs == true || rhs == true { return true }
                if lhs == false, rhs == false { return false }
                return nil
            default:
                return nil
            }
        }

        if let call = expression.as(FunctionCallExprSyntax.self),
           let function = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
           call.arguments.count == 1,
           let argument = call.arguments.first,
           argument.label == nil,
           let name = argument.expression.as(DeclReferenceExprSyntax.self)?.baseName.text {
            switch function {
            case "os":
                return isOperatingSystem(name)
            case "targetEnvironment":
                return isEnvironment(name)
            case "canImport":
                return canImport(name)
            default:
                return nil
            }
        }

        return nil
    }

    private func isOperatingSystem(_ name: String) -> Bool? {
        let known = Set(OperatingSystem.allCases.map(\.rawValue) + ["OSX", "Windows", "Android", "FreeBSD", "OpenBSD", "WASI"])
        guard known.contains(name) else {
            return nil
        }

        return name == os.rawValue || (name == "OSX" && os == .macOS)
    }

    private func isEnvironment(_ name: String) -> Bool? {
        switch name {
        case "simulator":
            return isSimulator
        case "macCatalyst":
            return false
        default:
            return nil
        }
    }

    /// Only system modules whose availability is certain. Any other module can come from a
    /// package or a framework, so Muter does not decide.
    private func canImport(_ module: String) -> Bool? {
        let isApple = os != .linux
        switch module {
        case "Foundation":
            return true
        case "Darwin":
            return isApple
        case "Glibc":
            // A Linux system can use another C library, such as musl.
            return isApple ? false : nil
        case "UIKit":
            return [.iOS, .tvOS, .visionOS, .watchOS].contains(os)
        case "AppKit":
            return os == .macOS
        default:
            return nil
        }
    }
}
