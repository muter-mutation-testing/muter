func alwaysReturnsFalse() -> Bool {
    return true == false
}

func shouldReturnTrue() -> Bool {
    return false || true
}

func shouldReturnTrue2() -> Bool {
    return true && false
}
