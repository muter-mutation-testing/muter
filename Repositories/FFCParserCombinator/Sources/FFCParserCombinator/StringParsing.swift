//
//  Tokens.swift
//  FFCParserCombinator
//
//  Created by Fabian Canas on 9/3/16.
//  Copyright © 2017 Fabian Canas. All rights reserved.
//

import Foundation

public extension Parser where S == Substring {
    /// Parses the full contents of the `String` parameter with a `Parser<Substring>`.
    ///
    /// This is useful because parsers of a `String` are easier to represent as
    /// parsers of a `Substring`. That is, when a `Parser` returns a result and
    /// a remainder, the remainer can be expressed as a `Substring` instead of
    /// upcasting to a new `String`.
    ///
    /// - Parameter x: The full `String` content to be parsed.
    /// - Returns: A result, `A` and a remainder, `Substring`
    func run(_ x: String) -> (A, Substring)? {
        return parse(x[x.fullRange])
    }

    /// Parses the full contents of the `Substring` parameter with a `Parser<Substring>`.
    ///
    /// - Parameter x: The `Substring` content to be parsed.
    /// - Returns: A result, `A` and a remainder, `Substring`
    func run(_ x: Substring) -> (A, Substring)? {
        return parse(x)
    }
}

/** Builds a `Parser` for matching a single character
 - parameter condition: A function that determines whether the character is parsed
                  (returns true) or causes the returned parser to fail (returns
                  false).
 - returns: A `Parser` for a single `Character` passing the provided `condition`
*/
public func character( condition: @escaping (Character) -> Bool) -> Parser<Substring, Character> {
    return Parser { stream in
        guard let char: Character = stream.first, condition(char) else { return nil }
        return (char, stream.dropFirst())
    }
}

extension CharacterSet {
    /** Builds a parser for matching a single character in the receiving
     `CharacterSet`
     - returns: A `Parser` that will match a single `Character` in `characterSet`
     */
    public func parser() -> Parser<Substring, Character> {
        return character(condition: { self.contains($0.unicodeScalar) } )
    }
}

extension Parser: ExpressibleByStringLiteral where A == String, S == Substring {
    public typealias StringLiteralType = String

    /// Creates an instance initialized to the given value.
    ///
    /// - Parameter value: The value of the new instance.
    public init(stringLiteral value: Parser.StringLiteralType) {
        self = value.parser()
    }
}

extension Parser: ExpressibleByExtendedGraphemeClusterLiteral where A == String, S == Substring {

    /// A type that represents an extended grapheme cluster literal.
    ///
    /// Valid types for `ExtendedGraphemeClusterLiteralType` are `Character`,
    /// `String`, and `StaticString`.
    public typealias ExtendedGraphemeClusterLiteralType = String

    /// Creates an instance initialized to the given value.
    ///
    /// - Parameter value: The value of the new instance.
    public init(extendedGraphemeClusterLiteral value: Parser.ExtendedGraphemeClusterLiteralType) {
        self = value.parser()
    }
}

extension Parser: ExpressibleByUnicodeScalarLiteral where A == String, S == Substring {

    public typealias UnicodeScalarLiteralType = String

    /// Creates an instance initialized to the given value.
    ///
    /// - Parameter value: The value of the new instance.
    public init(unicodeScalarLiteral value: Parser.UnicodeScalarLiteralType) {
        self = value.parser()
    }
}

extension String {
    /** Builds a parser for matching the receiving `String`
     */
    fileprivate func parser() -> Parser<Substring, String> {
        return Parser<Substring, String> { stream in
            var remainder = stream
            for char in self {
                guard let (_, newRemainder) = character(condition: { $0 == char }).parse(remainder) else {
                    return nil
                }
                remainder = newRemainder
            }
            return (self, remainder)
        }
    }

    internal var fullRange: Range<Index> {
        return Range(uncheckedBounds: (lower: startIndex, upper: endIndex))
    }
}

extension Character {
    /// The first `UnicodeScalar` of the `String` representation
    public var unicodeScalar: UnicodeScalar {
        return String(self).unicodeScalars.first!
    }
}

/// A `ParsableType` represents a type that provides a `Parser` for
/// that type in a `Substring` stream.
public protocol ParsableType {

    static var parser: Parser<Substring, Self> { get }
}

extension UInt: ParsableType {

    /// Returns a `Parser` that matches an `UInt` in a `Substring` stream.
    public static var parser: Parser<Substring, UInt> {
        return { UInt(String($0))! } <^> BasicParser.digit.many1
    }
}

extension Int: ParsableType {

    /// Returns a `Parser` that matches an `Int` in a `Substring` stream.
    public static var parser: Parser<Substring, Int> {
        return { characters in
            Int(String(characters))!
            } <^> BasicParser.negation.optional.followed(by: BasicParser.numericString, combine: { ($0 ?? "") + $1 } )
    }
}

extension Double: ParsableType {

    /// Returns a `Parser` that matches a `Double` from a Floating Point
    /// Literal in a `Substring` stream.
    ///
    /// The `Parser` attempts to match `Double` values with a definition
    /// closely matching the [Swift definition of a Floating Point Literal](https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html#ID416).
    ///
    /// ```
    /// decimal-digit → Digit 0 through 9
    /// decimal-literal-characters → decimal-digit decimal-digit opt
    /// decimal-literal → decimal-digit decimal-literal-characters opt
    /// floating-point-literal → decimal-literal decimal-fraction opt decimal-exponent opt
    /// decimal-fraction → . decimal-literal
    /// decimal-exponent → floating-point-e sign opt decimal-literal
    /// floating-point-e → e | E
    /// sign → + | -
    /// ```
    public static var parser: Parser<Substring, Double> {

        let m = { _ in FloatingPointSign.minus } <^> "-"
        let p = { _ in FloatingPointSign.plus } <^> "+"

        let sign = { $0 ?? FloatingPointSign.plus } <^> (p <|> m).optional

        let floatingPointE = "e" <|> "E"

        let decimalLiteral = UInt.parser

        let decimalFraction = "." *> ({ String($0) } <^> BasicParser.digit.many1)

        let decimalExponent = { (s, m) in Int(m) * (s == .minus ? -1 : 1) } <^> floatingPointE *> sign <&> UInt.parser

        let doubleParser = sign <&> decimalLiteral <<& decimalFraction.optional <<& decimalExponent.optional

        return { (sign, integerpart, fraction, radix10Exponent) in
            let s: String
            switch sign {
            case .plus:
                s = "+"
            case .minus:
                s = "-"
            }
            let frac: String
            switch fraction {
            case .none:
                frac = ""
            case let .some(f):
                frac = ".\(f)"
            }
            let exp: String
            switch radix10Exponent {
            case .none:
                exp = ""
            case let .some(e):
                let sign: String = e > 0 ? "+" : ""
                exp = "e\(sign)\(e)"
            }
            // I know this looks weird.
            // We're parsing a double to then piece it back together as a String
            // and let Swift parse it again and build a real Double?
            // I took a pass at building a Double from those pieces, and with
            // the radix change from the representation here in 10, to the
            // radix 2 needed for native representation, I was losing precision.
            // It turns out that even this method loses some precision, but a
            // little less than with my naive method.
            // This will do for now.
            // - fcanas
            return Double("\(s)\(integerpart)\(frac)\(exp)")!
            } <^> doubleParser
    }
}

/// A namespace containing static parsers for common basic types for
/// parsing out of a `Substring` stream.
public struct BasicParser {

    /// A `Parser` that matches and returns single decimal digit, `[0-9]` as
    /// a `Character` from a `Substring`.
    public static let digit = CharacterSet.decimalDigits.parser()

    /// A `Parser` that matches and returns single decimal digit, `[0-9][A-F]` as
    /// a `Character` from a `Substring`.
    public static let hexDigit = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "A"..."F")).parser()

    // Fragments

    /// A `Parser` that matches and returns "0x" or "0X" as a `String` from a
    /// 'Substring'.
    public static let hexPrefix = "0x".parser() <|> "0X".parser()

    /// A `Parser` that matches and returns single decimal dot, `.`, as
    /// a `String` from a `Substring`.
    public static let decimalPoint = ".".parser()

    /// A `Parser` that matches and returns single decimal hyphen, `-`, as
    /// a `String` from a `Substring`.
    public static let negation = "-".parser()

    /// A `Parser` that matches and returns a double-quote, `"`, as
    /// a `String` from a `Substring`.
    public static let quote = "\"".parser()

    /// A `Parser` that matches and returns a single x, `x`, as
    /// a `String` from a `Substring`.
    public static let x = character { $0 == "x" }

    /// A `Parser` that matches an abribrarily long sequence of decimal
    /// digits in `[0-9]` as a `String` in a `Substring`
    ///
    /// It is defined as
    /// ```
    /// { String($0) } <^> digit.many1
    /// ```
    public static let numericString = { String($0) } <^> digit.many1

    /// A `Parser` that matches an abribrarily long sequence of decimal
    /// digits in `[0-9]` with a single decimal point `.` as a `String`
    /// in a `Substring`
    ///
    /// It is defined as
    /// ```
    /// numericString.followed(by: decimalPoint, combine: +).followed(by: numericString, combine: +)
    /// ```
    public static let floatingPointString = numericString.followed(by: decimalPoint, combine: +).followed(by: numericString, combine: +)

    /// A `Parser` matching either a line feed carriage return, `\n\r`,
    /// or a single line feed `\n` as a `Character` in a `Substring`
    ///
    /// It is defined as
    /// ```
    /// character { $0 == "\n" } <* character { $0 == "\r" } <|> (character { $0 == "\n" } )
    /// ```
    public static let newline = character { $0 == "\n" } <* character { $0 == "\r" } <|> (character { $0 == "\n" } )
}
