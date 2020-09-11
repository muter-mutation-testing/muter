//
//  FFCParserCombinator.swift
//  FFCParserCombinator
//
//  Created by Fabian Canas on 9/3/16.
//  Adapted from https://github.com/objcio/s01e13-parsing-techniques
//

/// The core Parser type in FFCParserCombinator.
///
/// A parser is a function that accepts an S an input, optionally returning a
/// structure A and S.
///
/// S is commonly a String or Substring. A is a type to be constructed from
/// information found in the input S, and the returned S may be a remainder.
///
/// See static parsers in `BasicParser` for simple examples.
public struct Parser<S, A> {
    let parse: (S) -> (A, S)?
}

public extension Parser {

    /// Returns a Parser mapping the given closure over the receiving Parser's match.
    ///
    /// - Parameter transform: A mapping closure. transform accepts an match from this
    ///                        parser as its parameter and returns a transformed value
    ///                        of the same or of a different type.
    /// - Returns: A parser that matches according to the receiver with transform applied to
    ///            the matched results.
    func map<Result>(_ transform: @escaping (A) -> Result) -> Parser<S, Result> {
        return Parser<S, Result> { stream in
            guard let (result, newStream) = self.parse(stream) else { return nil }
            return (transform(result), newStream)
        }
    }

    /// Returns a Parser mapping the given closure over the receiving Parser's match
    /// if the transform returns a non-nil value.
    ///
    /// - Parameter transform: A mapping closure. transform accepts an match from this
    ///                        parser as its parameter and returns a transformed value
    ///                        of the same or of a different type.
    /// - Returns: A parser that matches according to the receiver with transform applied to
    ///            the matched results.
    func flatMap<Result>(_ transform: @escaping (A) -> Result?) -> Parser<S, Result> {
        return Parser<S, Result> { stream in
            guard let (result, newStream) = self.parse(stream) else { return nil }
            guard let mappedResult = transform(result) else { return nil }
            return (mappedResult, newStream)
        }
    }

    /// Parses zero or more consecutive elements into an array
    var many: Parser<S, [A]> {
        return atLeast(0)
    }

    /// Parses one or more consecutive elements into an array
    var many1: Parser<S, [A]> {
        return atLeast(1)
    }

    /// Parses `min` or more elements into an array
    ///
    /// - Parameter min: the minimum number of elements to match
    /// - Returns: A parser that matches the receiver at least `min` times.
    func atLeast(_ min: UInt) -> Parser<S, [A]> {
        return from(min, upTo: nil)
    }

    /// Parses `min` or more, up to `max` elements into an array.
    ///
    /// Each bound is inclusive: `[min, max]`
    ///
    /// - Parameters:
    ///   - min: the minimum number of elements to match
    ///   - max: the maximum number of elements to match
    /// - Returns: A parser that matches the receiver at least `min` times.
    func between(_ min: UInt, and max: UInt) -> Parser<S, [A]> {
        return from(min, upTo: max)
    }

    private func from(_ min: UInt, upTo max: UInt?) -> Parser<S, [A]> {
        return Parser<S, [A]> { stream in
            var result: [A] = []
            var remainder = stream
            while max == nil || result.count < max!, let (element, newRemainder) = self.parse(remainder) {
                remainder = newRemainder
                result.append(element)
            }
            if result.count < min {
                return nil
            }
            return (result, remainder)
        }
    }

    /// Returns a parser matching the as the reciver matches, or the `other`
    /// Parser matches, favoring the receiving parser.
    ///
    /// - SeeAlso: `<|>`
    /// - Parameters:
    ///   - lhs: The first matching parser
    ///   - rhs: The second matching parser
    /// - Returns: A parser matching lhs or rhs, with precendence given to lhs
    func or(_ other: Parser<S, A>) -> Parser<S, A> {
        return Parser { stream in
            return self.parse(stream) ?? other.parse(stream)
        }
    }

    /// Combines the receiving parser with `other` requiring the receiver to match and `other`
    /// to match immediately following. Results are combined by the passed `combine` function.
    ///
    /// To match `A` followed by `B` with the result being only `A`, use `<*`.
    ///
    /// To match `A` followed by `B` with the result being only `B`, use `*>`.
    ///
    /// To match `A` followed by `B` with the result being `(A', B')`, use `<&>`.
    ///
    /// - SeeAlso: `<*`, `*>`, `<&>`
    /// - Parameters:
    ///   - lhs: The first matching parser
    ///   - rhs: The second matching parser
    /// - Returns: A parser matching the lhs, then the rhs
    func followed<B, C>(by other: Parser<S, B>, combine: @escaping (A, B) -> C) -> Parser<S, C> {
        return Parser<S, C> { stream in
            guard let (result, remainder) = self.parse(stream) else { return nil }
            guard let (result2, remainder2) = other.parse(remainder) else { return nil }
            return (combine(result, result2), remainder2)
        }
    }

    /// Combines the receiver into a new `Parser` that appends the results of the
    /// receiver to the results of the `other` parameter.
    ///
    /// This is very much like `<&>` or `followed(by:, combine:)` with a 2-arity
    ///
    /// - SeeAlso: `group<B, C, D>(into other: Parser<S, (B, C, D)>) -> Parser<S, (B, C, D, A)>`
    /// - Parameter other: A `Parser` of 2-element tuple whose reults prefix the
    ///                    receiver's results in a 3-element tuple
    /// - Returns: A `Parser` matching `other` followed by the receiver that generates
    ///            a 3-element tuple
    func group<B, C>(into other: Parser<S, (B, C)>) -> Parser<S, (B, C, A)> {
        return Parser<S, (B, C, A)> { stream in
            guard let (resultBC, remainderBC) = other.parse(stream) else { return nil }
            guard let (result, remainder) = self.parse(remainderBC) else { return nil }
            return ((resultBC.0, resultBC.1, result), remainder)
        }
    }

    /// Combines the receiver into a new `Parser` that appends the results of the
    /// receiver to the results of the `other` parameter.
    ///
    /// This is very much like `<&>` or `followed(by:, combine:)` with a 3-arity
    ///
    /// - SeeAlso: `group<B, C>(into other: Parser<S, (B, C)>) -> Parser<S, (B, C, A)>`
    /// - Parameter other: A `Parser` of 3-element tuple whose reults prefix the
    ///                    receiver's results in a 4-element tuple
    /// - Returns: A `Parser` matching `other` followed by the receiver that generates
    ///            a 4-element tuple
    func group<B, C, D>(into other: Parser<S, (B, C, D)>) -> Parser<S, (B, C, D, A)> {
        return Parser<S, (B, C, D, A)> { stream in
            guard let (resultBCD, remainderBCD) = other.parse(stream) else { return nil }
            guard let (result, remainder) = self.parse(remainderBCD) else { return nil }
            return ((resultBCD.0, resultBCD.1, resultBCD.2, result), remainder)
        }
    }

    /// Initializes a `Parser` that generates a fixed `result: A` and passes
    /// `stream: S` unmodified to its output.
    ///
    /// - Parameter result: An argument passed unmodified to the `Parser`'s
    ///                     output alongside the unmodified input stream.
    init(result: A) {
        parse = { stream in (result, stream) }
    }

    /// A derived parser that generates an optional, returing `.some(A)` when
    /// a match occurs, and `.none` when there is no match.
    var optional: Parser<S, A?> {
        return self.map({ .some($0) }).or(Parser<S, A?>(result: nil))
    }
    
    /// Returns a Parser that matches the same as a receiver without consuming
    /// from the source stream.
    func backtrack() -> Parser<S, A> {
        return Parser<S, A> { stream in
            guard let (result, _) = self.parse(stream) else { return nil }
            return (result, stream)
        }
    }
}

internal func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { x in { y in f(x, y) } }
}

precedencegroup ParserPrecedence {
    associativity: left
    higherThan: ParserConjuctionPrecedence
}

precedencegroup ParserConjuctionPrecedence {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: ParserMapPrecedence
}

precedencegroup ParserMapPrecedence {
    associativity: left
    higherThan: ParserGroupPrecendence
}

precedencegroup ParserGroupPrecendence {
    associativity: left
}

/// Operators

infix operator <^> : ParserMapPrecedence
infix operator <^!> : ParserMapPrecedence
infix operator <*> : ParserPrecedence
infix operator <&> : ParserPrecedence
infix operator *>  : ParserPrecedence
infix operator <*  : ParserPrecedence
infix operator <|> : ParserConjuctionPrecedence
infix operator <<&  : ParserGroupPrecendence

/// Returns a Parser mapping the given lhs closure over the rhs Parser's match.
///
/// - Parameter transform: A mapping closure. transform accepts an match from the rhs
///                        parser as its parameter and returns a transformed value
///                        of the same or of a different type.
///            rhs: A `Parser` responsibld for matching whose result will be transformed
///                 by transform
/// - Returns: A parser that matches according to the rhs with transform applied to
///            the matched results.
public func <^><S, A, B>(transform: @escaping (A) -> B, rhs: Parser<S, A>) -> Parser<S, B> {
    return rhs.map(transform)
}

/// Returns a Parser flat-mapping the given lhs closure over the rhs Parser's match.
///
/// - Parameter transform: A mapping closure. transform accepts an match from the rhs
///                        parser as its parameter and returns a transformed value
///                        of the same or of a different type. A nil return will be
///                        excluded from the result stream.
///            rhs: A `Parser` responsibld for matching whose result will be transformed
///                 by transform
/// - Returns: A parser that matches according to the rhs with transform applied to
///            the matched results.
public func <^!><S, A, B>(f: @escaping (A) -> B?, rhs: Parser<S, A>) -> Parser<S, B> {
    return rhs.flatMap(f)
}

public func <^><S, A, B, R>(f: @escaping (A, B) -> R, rhs: Parser<S, A>) -> Parser<S, (B) -> R> {
    return Parser(result: curry(f)) <*> rhs
}

public func <*><S, A, B>(lhs: Parser<S, (A) -> B>, rhs: Parser<S, A>) -> Parser<S, B> {
    return lhs.followed(by: rhs, combine: { $0($1) })
}

/// Combines two parsers to a single parser matching the lhs followed by
/// the rhs, returning the values matched by each in a tuple.
///
/// - Parameters:
///   - lhs: The first matching parser
///   - rhs: The second matching parser
/// - Returns: A parser matching the lhs, then the rhs
public func <&><S, A, B>(lhs: Parser<S, A>, rhs: Parser<S, B>) -> Parser<S, (A, B)> {
    return lhs.followed(by: rhs, combine: { ($0, $1) })
}

/// Returns a parser matching the lhs followed by the rhs, only returning
/// the value matched by the lhs parser in the case both match.
///
/// - Parameters:
///   - lhs: The first matching parser, the result of the expression
///   - rhs: The second matching parser
/// - Returns: The lhs parser in the case both lhs and rhs match
public func <*<S, A, B>(lhs: Parser<S, A>, rhs: Parser<S, B>) -> Parser<S, A> {
    return lhs.followed(by: rhs, combine: { x, _ in x })
}

/// Returns a parser matching the lhs following the rhs, only returning the
/// value matched by the rhs parser in the case both match.
///
/// - Parameters:
///   - lhs: The first matching parser
///   - rhs: The second matching parser, the result of the expression
/// - Returns: The rhs parser in the case both lhs and rhs match
public func *><S, A, B>(lhs: Parser<S, A>, rhs: Parser<S, B>) -> Parser<S, B> {
    return lhs.followed(by: rhs, combine: { _, x in x })
}

/// Returns a parser matching the lhs or the rhs, only returning the
/// first value matched.
///
/// - Parameters:
///   - lhs: The first matching parser
///   - rhs: The second matching parser
/// - Returns: A parser matching lhs or rhs, with precendence given to lhs
public func <|><S, A>(lhs: Parser<S, A>, rhs: Parser<S, A>) -> Parser<S, A> {
    return lhs.or(rhs)
}

/// Combines `lhs` and `rhs` into a new `Parser` that appends the results of the
/// `rhs` to the results of `lhs`.
///
/// This is very much like `<&>` with a 2-arity for `lhs`
///
/// - Parameters:
///   - lhs: A `Parser` of 2-element tuple that will match first, and whose results
///          will be the first 2 elements of the returned `Parser`'s results
///   - rhs: A `Parser` of a single element that will match second, and whose results
///          will be the last element of the returned `Parser`'s results
/// - Returns: A parser matching `lhs` followed by `rhs` with results combined into a
///            tuple in order.
public func <<&<S, A, B, C>(lhs: Parser<S, (A, B)>, rhs: Parser<S, C>) -> Parser<S, (A, B, C)> {
    return rhs.group(into: lhs)
}

/// Combines `lhs` and `rhs` into a new `Parser` that appends the results of the
/// `rhs` to the results of `lhs`.
///
/// This is very much like `<&>` with a 3-arity for `lhs`
///
/// - Parameters:
///   - lhs: A `Parser` of 3-element tuple that will match first, and whose results
///          will be the first 3 elements of the returned `Parser`'s results
///   - rhs: A `Parser` of a single element that will match second, and whose results
///          will be the last element of the returned `Parser`'s results
/// - Returns: A parser matching `lhs` followed by `rhs` with results combined into a
///            tuple in order.
public func <<&<S, A, B, C, D>(lhs: Parser<S, (A, B, C)>, rhs: Parser<S, D>) -> Parser<S, (A, B, C, D)> {
    return rhs.group(into: lhs)
}
