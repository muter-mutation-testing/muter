#if os(iOS) || os(tvOS)
print("please ignore me")
#endif

func someCode(_ a: Bool, _ b: Bool) -> Bool {
    return a ? b ? false : true: false
}
