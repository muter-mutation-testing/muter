#if os(iOS) || os(tvOS)
print("please ignore me")
#endif

func someCode(_ a: Bool) -> Bool {
    return a ? true : false
}

func someAnotherCode(_ a: Bool) -> String {
    return a ? "true" : "false"
}
