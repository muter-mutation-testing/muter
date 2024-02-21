struct Example {
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
}

func < (lhs: String, rhs: String) -> Bool {
    return false
}

internal func isBare() throws -> Bool {
    return try self.cachedIsBareRepo.memoize(body: {
        let output = try callGit(
            "rev-parse",
            "--is-bare-repository",
            failureMessage: "Couldn’t test for bare repository"
        )

        return output == "true"
    })
}
