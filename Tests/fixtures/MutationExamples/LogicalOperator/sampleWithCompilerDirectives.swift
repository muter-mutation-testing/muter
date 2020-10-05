#if os(iOS) || os(tvOS)
print("hello")
#endif

#if swift(>=4.2) && os(iOS) || os(tvOS)
func someCode() -> Bool {
    return false && false
}
#endif
