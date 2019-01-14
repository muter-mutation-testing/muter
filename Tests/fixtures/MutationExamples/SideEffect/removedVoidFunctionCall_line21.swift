struct Example {
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
    }

    func containsSpecialCases() {
        fatalError("this should never be deleted!")
        exit(1)
        abort()
    }

    func containsADeepMethodCall() {
        let containsIgnoredResult = statement.description.contains("lol")
        var anotherIgnoredResult = statement.description.contains("lol")
    }

    func containsAVoidFunctionCallThatSpansManyLine() {
        functionCall("some argument",
                     anArgumentLabel: "some argument that's different",
                     anotherArgumentLabel: 5)
    }

    func containsAVoidFunctionCallInsideAForLoop() {
        var positionsOfToken: [AbsolutePosition] = []
        for statement in body.statements where statementContainsMutableToken(statement) {
            positionsOfToken.append(position)
        }
    }

    func containsAVoidFunctionCallThatThrows() {
        try toDoSomethingThatThrows()
    }
}

func containSideEffects(_ a: Int) -> String {
    let b = something()
    _ = returnsSomethingThatGetsIgnored()
    voidFunctionCall()
    return ""
}

extension Array where Element: Hashable  {
    func deduplicated() -> Array {
        return Set(self).map{ $0 }
    }
}

func thisShouldBeIgnored() {
    return CLITable(padding: 3, columns: [
        CLITable.Column(title: "File", rows: fileNames),
        CLITable.Column(title: "Position", rows: positions),
        CLITable.Column(title: "Applied Mutation Operator", rows: appliedMutations),
        CLITable.Column(title: "Mutation Test Result", rows: mutationTestResults),
    ])
}

func applyMutationScoreColor(to rows: [CLITable.Row]) -> [CLITable.Row] {
    return rows.map {
        let coloredValue = coloredMutationScore(for: Int($0.value)!, appliedTo: $0.value)
        return CLITable.Row(value: coloredValue)
    }
}

public extension AbsolutePosition {
    public static var firstPosition: AbsolutePosition {
        return AbsolutePosition(line: 0, column: 0, utf8Offset: 0)
    }
}
