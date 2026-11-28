import SwiftOperators
import SwiftSyntax

/// Swaps `+` and `-`, and `*` and `/`, and their compound assignments, such as `+=` and `-=`.
///
/// All mutants build together, so a mutant that does not compile stops the whole run. This
/// operator mutates only when the index store shows that the operator is the arithmetic of a
/// number type, such as `Int.+`, and that the type also has the new operator. It leaves alone
/// `String` concatenation, `Date + TimeInterval`, a project's own operators, and code without an
/// index.
///
/// The compiler also rejects an integer operation that it can compute at build time and that
/// overflows or divides by zero, such as `10 - 20` for `UInt8` or `y / 0`, even in a mutant that
/// never runs. So for an integer type, one operand must be a value that is known only at run time,
/// and a new divisor must be such a value or a literal other than zero.
enum ArithmeticOperatorReplacement {
    static let replacements = [
        "+": "-",
        "-": "+",
        "*": "/",
        "/": "*",
        "+=": "-=",
        "-=": "+=",
        "*=": "/=",
        "/=": "*=",
    ]

    /// The names that the index store gives these operators, such as `+(_:_:)`.
    static let symbolNames = Set(replacements.keys.map { "\($0)(_:_:)" })

    class Visitor: TokenAwareVisitor {
        /// The local names of each function, by its node: a long function has many operands.
        private var localNamesByFunction: [SyntaxIdentifier: Set<String>] = [:]

        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo,
            regionsWithoutCoverage: [Region] = []
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .aor,
                regionsWithoutCoverage: regionsWithoutCoverage
            )

            tokensToDiscover = replacements.keys.sorted().map { .binaryOperator($0) }
            oppositeOperatorMapping = replacements
        }

        override func canMutate(_ node: BinaryOperatorExprSyntax, to replacement: String) -> Bool {
            guard let symbolIndex,
                  let symbol = referencedSymbol(at: node.operator),
                  let signature = symbolIndex.signature(of: symbol),
                  let operation = ArithmeticOperation(signature: signature, operator: node.operator.text),
                  operation.typeHas(replacement)
            else {
                return false
            }

            guard operation.isConcreteInteger else {
                return true
            }

            guard let operands = operands(of: node) else {
                return false
            }

            guard isKnownOnlyAtRunTime(operands.left) || isKnownOnlyAtRunTime(operands.right) else {
                return false
            }

            if replacement == "/" || replacement == "/=" {
                return isKnownOnlyAtRunTime(operands.right) || operands.right.expression.isNonZeroIntegerLiteral
            }

            return true
        }

        // MARK: - Operands

        private struct Operand {
            /// The operand in the folded expression.
            let expression: ExprSyntax
            /// The tokens of the operand in the source file.
            let tokens: [TokenSyntax]
        }

        /// The two operands of the operator, with the precedence of the standard operators. A
        /// sequence with an operator that the standard table does not know gives none.
        private func operands(of node: BinaryOperatorExprSyntax) -> (left: Operand, right: Operand)? {
            guard let sequence = node.parent?.parent?.as(SequenceExprSyntax.self),
                  let folded = try? OperatorTable.standardOperators.foldAll(sequence)
            else {
                return nil
            }

            // The folded tree has the same text, so offsets from its start match the source.
            let foldedStart = folded.position.utf8Offset
            let sequenceStart = sequence.position.utf8Offset
            let operatorOffset = node.operator.position.utf8Offset - sequenceStart
            guard let infix = folded.descendants(InfixOperatorExprSyntax.self).first(where: {
                $0.operator.position.utf8Offset - foldedStart == operatorOffset
            }) else {
                return nil
            }

            let sequenceTokens = Array(sequence.tokens(viewMode: .sourceAccurate))
            func operand(_ expression: ExprSyntax) -> Operand {
                let start = expression.positionAfterSkippingLeadingTrivia.utf8Offset - foldedStart + sequenceStart
                let end = expression.endPositionBeforeTrailingTrivia.utf8Offset - foldedStart + sequenceStart
                let tokens = sequenceTokens.filter {
                    $0.positionAfterSkippingLeadingTrivia.utf8Offset >= start &&
                        $0.endPositionBeforeTrailingTrivia.utf8Offset <= end
                }
                return Operand(expression: expression, tokens: tokens)
            }

            return (operand(infix.leftOperand), operand(infix.rightOperand))
        }

        // MARK: - Values known only at run time

        /// Whether the operand uses a value that the compiler cannot compute at build time: a
        /// parameter, `self`, or a property or function of the project. A literal, a local
        /// constant or variable, and a system value such as `Int.max` may be computed at build time.
        private func isKnownOnlyAtRunTime(_ operand: Operand) -> Bool {
            operand.tokens.contains { token in
                switch token.tokenKind {
                case .keyword(.self), .keyword(.super), .dollarIdentifier:
                    return true
                case let .identifier(name):
                    guard let reference = token.parent?.as(DeclReferenceExprSyntax.self) else {
                        return false
                    }
                    if let symbol = referencedSymbol(at: token) {
                        return isProjectValue(symbol)
                    }
                    // The index has no references to parameters and local values.
                    return !reference.isMemberName && isParameter(name, at: token)
                default:
                    return false
                }
            }
        }

        private func isProjectValue(_ symbol: IndexSymbol) -> Bool {
            // A global constant can be computed at build time in `main.swift`.
            symbolIndex?.defines(symbol) == true && !symbol.kind.isType && symbol.kind != .variable
        }

        /// Whether `name` at `token` is a parameter of a function, initializer, subscript, accessor
        /// or closure around it. A name that the function also binds to a local value does not
        /// count, because Muter cannot tell which one the token uses.
        private func isParameter(_ name: String, at token: TokenSyntax) -> Bool {
            var parameters = Set<String>()
            var outermost: Syntax?
            var current = token.parent
            while let node = current {
                if node.isProtocol(DeclGroupSyntax.self) || node.is(SourceFileSyntax.self) {
                    break
                }
                if let names = node.parameterNames {
                    parameters.formUnion(names)
                    outermost = node
                }
                current = node.parent
            }

            guard parameters.contains(name), let outermost else {
                return false
            }

            let localNames = localNamesByFunction[outermost.id] ?? outermost.localNames
            localNamesByFunction[outermost.id] = localNames
            return !localNames.contains(name)
        }
    }
}

/// An arithmetic operator function, read from its signature, such as
/// `static Swift.Int.+ infix(Swift.Int, Swift.Int) -> Swift.Int` or, in generic code,
/// `static Swift.AdditiveArithmetic.+ infix(A, A) -> A`.
struct ArithmeticOperation: Equatable {
    static let integerTypes: Set<String> = [
        "Swift.Int", "Swift.Int8", "Swift.Int16", "Swift.Int32", "Swift.Int64", "Swift.Int128",
        "Swift.UInt", "Swift.UInt8", "Swift.UInt16", "Swift.UInt32", "Swift.UInt64", "Swift.UInt128",
    ]

    static let otherNumberTypes: Set<String> = [
        "Swift.Float", "Swift.Double", "Swift.Float16", "Swift.Float80",
        "CoreFoundation.CGFloat", "CoreGraphics.CGFloat", "Foundation.CGFloat",
        "__C.NSDecimal", "Foundation.Decimal", "FoundationEssentials.Decimal",
    ]

    /// Protocols that have all four operators: they refine `Numeric`, and `BinaryInteger` or
    /// `FloatingPoint`, which add `/`.
    static let protocolsWithDivision: Set<String> = [
        "Swift.BinaryInteger", "Swift.FixedWidthInteger", "Swift.SignedInteger", "Swift.UnsignedInteger",
        "Swift.FloatingPoint", "Swift.BinaryFloatingPoint",
    ]

    /// `AdditiveArithmetic` has only `+` and `-`. `Numeric` adds `*` but not `/`, so its `*` has
    /// no replacement.
    static let additiveProtocols: Set<String> = ["Swift.AdditiveArithmetic"]

    /// The type or protocol that declares the operator.
    let owner: String

    init?(signature: String, operator: String) {
        guard signature.hasPrefix("static ") else {
            return nil
        }

        var rest = signature.dropFirst("static ".count)
        // An operator in an extension of a type from another module, such as Foundation's
        // `Decimal.+`, reads `(extension in Foundation):__C.NSDecimal.+ infix(...)`.
        if rest.hasPrefix("(extension in "), let colon = rest.firstIndex(of: ":") {
            rest = rest[rest.index(after: colon)...]
        }

        guard let name = rest.range(of: ".\(`operator`) infix("),
              let arrow = rest.range(of: ") -> ", range: name.upperBound ..< rest.endIndex)
        else {
            return nil
        }

        let owner = String(rest[..<name.lowerBound])
        let parameters = rest[name.upperBound ..< arrow.lowerBound].components(separatedBy: ", ")
        let result = String(rest[arrow.upperBound...])
        let isCompound = `operator`.hasSuffix("=")

        guard parameters.count == 2 else {
            return nil
        }

        let left = isCompound ? parameters[0].replacingOccurrences(of: "inout ", with: "") : parameters[0]
        let operandType = parameters[1]
        guard left == operandType,
              result == (isCompound ? "()" : operandType)
        else {
            return nil
        }

        let isConcrete = operandType == owner &&
            (Self.integerTypes.contains(owner) || Self.otherNumberTypes.contains(owner))
        // In a generic function, the operands have the type of a generic parameter, such as `A`.
        let isGeneric = operandType.first?.isUppercase == true && !operandType.contains(".") &&
            (Self.protocolsWithDivision.contains(owner) || Self.additiveProtocols.contains(owner))
        guard isConcrete || isGeneric else {
            return nil
        }

        self.owner = owner
    }

    /// Whether the compiler can compute the operation at build time, and then rejects one that
    /// overflows or divides by zero.
    var isConcreteInteger: Bool {
        Self.integerTypes.contains(owner)
    }

    func typeHas(_ operator: String) -> Bool {
        if Self.additiveProtocols.contains(owner) {
            return ["+", "-", "+=", "-="].contains(`operator`)
        }

        return true
    }
}

private extension Syntax {
    /// The names of the parameters, when the node is a function, an initializer, a subscript, an
    /// accessor or a closure.
    var parameterNames: Set<String>? {
        if let function = self.as(FunctionDeclSyntax.self) {
            return function.signature.parameterClause.parameters.names
        }
        if let initializer = self.as(InitializerDeclSyntax.self) {
            return initializer.signature.parameterClause.parameters.names
        }
        if let subscriptDecl = self.as(SubscriptDeclSyntax.self) {
            return subscriptDecl.parameterClause.parameters.names
        }
        if let accessor = self.as(AccessorDeclSyntax.self) {
            if let parameter = accessor.parameters {
                return [parameter.name.text]
            }
            switch accessor.accessorSpecifier.tokenKind {
            case .keyword(.set), .keyword(.willSet):
                return ["newValue"]
            case .keyword(.didSet):
                return ["oldValue"]
            default:
                return []
            }
        }
        if let closure = self.as(ClosureExprSyntax.self) {
            switch closure.signature?.parameterClause {
            case let .simpleInput(parameters):
                return Set(parameters.map(\.name.text))
            case let .parameterClause(clause):
                return Set(clause.parameters.map { ($0.secondName ?? $0.firstName).text })
            case nil:
                return []
            }
        }
        return nil
    }

    /// The names that the code inside binds to local constants, variables and captures.
    var localNames: Set<String> {
        var names = Set(descendants(IdentifierPatternSyntax.self).map(\.identifier.text))
        names.formUnion(descendants(ClosureCaptureSyntax.self).map(\.name.text))
        return names
    }

    /// The node and the nodes inside it that have the type `T`.
    func descendants<T: SyntaxProtocol>(_ type: T.Type) -> [T] {
        var found: [T] = []
        var pending: [Syntax] = [self]
        while let node = pending.popLast() {
            if let match = node.as(T.self) {
                found.append(match)
            }
            pending.append(contentsOf: node.children(viewMode: .sourceAccurate))
        }
        return found
    }
}

private extension FunctionParameterListSyntax {
    var names: Set<String> {
        Set(map { ($0.secondName ?? $0.firstName).text })
    }
}

private extension DeclReferenceExprSyntax {
    /// Whether the reference is the member in `base.member`.
    var isMemberName: Bool {
        parent?.as(MemberAccessExprSyntax.self)?.declName.id == id
    }
}

private extension ExprSyntax {
    var isNonZeroIntegerLiteral: Bool {
        if let tuple = self.as(TupleExprSyntax.self), tuple.elements.count == 1,
           let element = tuple.elements.first, element.label == nil {
            return element.expression.isNonZeroIntegerLiteral
        }
        if let prefix = self.as(PrefixOperatorExprSyntax.self), prefix.operator.text == "-" {
            return prefix.expression.isNonZeroIntegerLiteral
        }
        guard let literal = self.as(IntegerLiteralExprSyntax.self) else {
            return false
        }

        var digits = literal.literal.text.replacingOccurrences(of: "_", with: "")
        for prefix in ["0x", "0o", "0b"] where digits.hasPrefix(prefix) {
            digits.removeFirst(prefix.count)
        }
        return digits.contains { $0 != "0" }
    }
}
