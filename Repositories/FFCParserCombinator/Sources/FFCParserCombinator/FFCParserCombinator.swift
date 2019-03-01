//
//  FFCParserCombinator.swift
//  FFCParserCombinator
//
//  Created by Fabian Canas on 9/3/16.
//  Adapted from https://github.com/objcio/s01e13-parsing-techniques
//

public struct Parser<S,A> {
    let parse: (S) -> (A, S)?
}

public extension Parser {

    func map<Result>(_ f: @escaping (A) -> Result) -> Parser<S,Result> {
        return Parser<S,Result> { stream in
            guard let (result, newStream) = self.parse(stream) else { return nil }
            return (f(result), newStream)
        }
    }

    func flatMap<Result>(_ f: @escaping (A) -> Result?) -> Parser<S,Result> {
        return Parser<S,Result> { stream in
            guard let (result, newStream) = self.parse(stream) else { return nil }
            guard let mappedResult = f(result) else { return nil }
            return (mappedResult, newStream)
        }
    }

    /// Parses zero or more consecutive elements into an array
    public var many: Parser<S,[A]> {
        return atLeast(0)
    }

    /// Parses one or more consecutive elements into an array
    public var many1: Parser<S,[A]> {
        return atLeast(1)
    }

    /// Parses `min` or more elements into an array
    ///
    /// - Parameter min: the minimum number of elements to match
    /// - Returns: A parser that matches the receiver at least `min` times.
    public func atLeast(_ min: UInt) -> Parser<S,[A]> {
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
    public func between(_ min: UInt, and max: UInt) -> Parser<S,[A]> {
        return from(min, upTo: max)
    }

    private func from(_ min: UInt, upTo max: UInt?) -> Parser<S,[A]> {
        return Parser<S,[A]> { stream in
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

    func or(_ other: Parser<S,A>) -> Parser<S,A> {
        return Parser { stream in
            return self.parse(stream) ?? other.parse(stream)
        }
    }

    func followed<B, C>(by other: Parser<S,B>, combine: @escaping (A, B) -> C) -> Parser<S,C> {
        return Parser<S,C> { stream in
            guard let (result, remainder) = self.parse(stream) else { return nil }
            guard let (result2, remainder2) = other.parse(remainder) else { return nil }
            return (combine(result,result2), remainder2)
        }
    }

    func followed<B>(by other: Parser<S,B>) -> Parser<S,(A, B)> {
        return followed(by: other, combine: { ($0, $1) })
    }

    func group<B, C>(into other: Parser<S,(B, C)>) -> Parser<S,(B, C, A)> {
        return Parser<S,(B, C, A)> { stream in
            guard let (resultBC, remainderBC) = other.parse(stream) else { return nil }
            guard let (result, remainder) = self.parse(remainderBC) else { return nil }
            return ((resultBC.0, resultBC.1, result), remainder)
        }
    }

    func group<B, C, D>(into other: Parser<S,(B, C, D)>) -> Parser<S,(B, C, D, A)> {
        return Parser<S,(B, C, D, A)> { stream in
            guard let (resultBCD, remainderBCD) = other.parse(stream) else { return nil }
            guard let (result, remainder) = self.parse(remainderBCD) else { return nil }
            return ((resultBCD.0, resultBCD.1, resultBCD.2, result), remainder)
        }
    }

    init(result: A) {
        parse = { stream in (result, stream) }
    }

    var optional: Parser<S,A?> {
        return self.map({ .some($0) }).or(Parser<S,A?>(result: nil))
    }
}


func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
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

public func <^><S, A, B>(f: @escaping (A) -> B, rhs: Parser<S,A>) -> Parser<S,B> {
    return rhs.map(f)
}

public func <^!><S, A, B>(f: @escaping (A) -> B?, rhs: Parser<S,A>) -> Parser<S,B> {
    return rhs.flatMap(f)
}

public func <^><S, A, B, R>(f: @escaping (A, B) -> R, rhs: Parser<S,A>) -> Parser<S,(B) -> R> {
    return Parser(result: curry(f)) <*> rhs
}

public func <*><S, A, B>(lhs: Parser<S, (A) -> B>, rhs: Parser<S,A>) -> Parser<S,B> {
    return lhs.followed(by: rhs, combine: { $0($1) })
}

public func <&><S, A, B>(lhs: Parser<S,A>, rhs: Parser<S,B>) -> Parser<S,(A,B)> {
    return lhs.followed(by: rhs, combine: { ($0, $1) })
}

/// Returns a parser matching the lhs following the rhs, only returning the
/// value matched by the lhs parser in the case both match.
///
/// - Parameters:
///   - lhs: The first matching parser, the result of the expression
///   - rhs: The second matching parser
/// - Returns: The lhs parser in the case both lhs and rhs match
public func <*<S, A, B>(lhs: Parser<S,A>, rhs: Parser<S,B>) -> Parser<S,A> {
    return lhs.followed(by: rhs, combine: { x, _ in x })
}

/// Returns a parser matching the lhs following the rhs, only returning the
/// value matched by the rhs parser in the case both match.
///
/// - Parameters:
///   - lhs: The first matching parser
///   - rhs: The second matching parser, the result of the expression
/// - Returns: The rhs parser in the case both lhs and rhs match
public func *><S, A, B>(lhs: Parser<S,A>, rhs: Parser<S,B>) -> Parser<S,B> {
    return lhs.followed(by: rhs, combine: { _, x in x })
}

public func <|><S, A>(lhs: Parser<S,A>, rhs: Parser<S,A>) -> Parser<S,A> {
    return lhs.or(rhs)
}

public func <<&<S, A, B, C>(lhs: Parser<S,(A, B)>, rhs: Parser<S,C>) -> Parser<S,(A, B, C)> {
    return rhs.group(into:lhs)
}

public func <<&<S, A, B, C, D>(lhs: Parser<S,(A, B, C)>, rhs: Parser<S,D>) -> Parser<S,(A, B, C, D)> {
    return rhs.group(into:lhs)
}
