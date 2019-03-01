extension Parser: ExpressibleByStringLiteral where A == String, S == Substring {
    public typealias StringLiteralType = String

    public init(stringLiteral value: Parser.StringLiteralType) {
        self = value.parser()
    }
}