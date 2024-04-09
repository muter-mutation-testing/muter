#if os(iOS) || os(tvOS)
print("please ignore me")
#endif

func someCode() -> Bool {
    return false && false
}

func someOtherCode() -> Bool {
    return true || true
}

func isEnabledToShow() -> Bool {
    // バルーンの表示判定
    return false && false
}
