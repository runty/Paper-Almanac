// A bounded, strict JSON reader for the current pack format. Rejects numeric literals,
// duplicate keys, excessive nesting, oversized strings and invalid UTF-8; produces CanonicalValue.

import TungShingCore

public struct JSONLimits: Sendable, Hashable {
    public var maximumBytes: Int = 128 * 1024 * 1024
    public var maximumDepth: Int = 32
    public var maximumStringBytes: Int = 16 * 1024
    public init() {}
    public static let packDefaults = JSONLimits()
}

public enum StrictJSONError: Error, Sendable, Hashable {
    case tooLarge(Int)
    case invalidUTF8
    case unexpectedByte(offset: Int)
    case unexpectedEnd
    case numericLiteral(offset: Int)
    case duplicateKey(String)
    case depthExceeded
    case stringTooLong
    case invalidEscape(offset: Int)
    case trailingContent(offset: Int)
    case unpairedSurrogate(offset: Int)
}

public struct StrictJSONParser {
    private let bytes: [UInt8]
    private let limits: JSONLimits
    private var i = 0

    public static func parse(_ bytes: [UInt8], limits: JSONLimits = .packDefaults) throws -> CanonicalValue {
        guard bytes.count <= limits.maximumBytes else { throw StrictJSONError.tooLarge(bytes.count) }
        guard String(validating: bytes, as: UTF8.self) != nil else { throw StrictJSONError.invalidUTF8 }
        var parser = StrictJSONParser(bytes: bytes, limits: limits)
        parser.skipWhitespace()
        let value = try parser.parseValue(depth: 0)
        parser.skipWhitespace()
        guard parser.i == bytes.count else { throw StrictJSONError.trailingContent(offset: parser.i) }
        return value
    }

    private init(bytes: [UInt8], limits: JSONLimits) {
        self.bytes = bytes
        self.limits = limits
    }

    private mutating func skipWhitespace() {
        while i < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[i]) { i += 1 }
    }

    private mutating func parseValue(depth: Int) throws -> CanonicalValue {
        guard i < bytes.count else { throw StrictJSONError.unexpectedEnd }
        switch bytes[i] {
        case 0x7B: return try parseObject(depth: depth + 1)
        case 0x5B: return try parseArray(depth: depth + 1)
        case 0x22: return .string(try parseString())
        case 0x74: try expectLiteral("true"); return .bool(true)
        case 0x66: try expectLiteral("false"); return .bool(false)
        case 0x6E: try expectLiteral("null"); return .null
        case 0x2D, 0x30...0x39: throw StrictJSONError.numericLiteral(offset: i)
        default: throw StrictJSONError.unexpectedByte(offset: i)
        }
    }

    private mutating func expectLiteral(_ literal: String) throws {
        let lit = Array(literal.utf8)
        guard i + lit.count <= bytes.count, Array(bytes[i..<(i + lit.count)]) == lit else { throw StrictJSONError.unexpectedByte(offset: i) }
        i += lit.count
    }

    private mutating func parseObject(depth: Int) throws -> CanonicalValue {
        guard depth <= limits.maximumDepth else { throw StrictJSONError.depthExceeded }
        i += 1
        var dict: [String: CanonicalValue] = [:]
        skipWhitespace()
        if i < bytes.count, bytes[i] == 0x7D { i += 1; return .object(dict) }
        while true {
            skipWhitespace()
            guard i < bytes.count, bytes[i] == 0x22 else { throw StrictJSONError.unexpectedByte(offset: i) }
            let key = try parseString()
            guard dict[key] == nil else { throw StrictJSONError.duplicateKey(key) }
            skipWhitespace()
            guard i < bytes.count, bytes[i] == 0x3A else { throw StrictJSONError.unexpectedByte(offset: i) }
            i += 1
            skipWhitespace()
            dict[key] = try parseValue(depth: depth)
            skipWhitespace()
            guard i < bytes.count else { throw StrictJSONError.unexpectedEnd }
            if bytes[i] == 0x2C { i += 1; continue }
            if bytes[i] == 0x7D { i += 1; return .object(dict) }
            throw StrictJSONError.unexpectedByte(offset: i)
        }
    }

    private mutating func parseArray(depth: Int) throws -> CanonicalValue {
        guard depth <= limits.maximumDepth else { throw StrictJSONError.depthExceeded }
        i += 1
        var items: [CanonicalValue] = []
        skipWhitespace()
        if i < bytes.count, bytes[i] == 0x5D { i += 1; return .array(items) }
        while true {
            skipWhitespace()
            items.append(try parseValue(depth: depth))
            skipWhitespace()
            guard i < bytes.count else { throw StrictJSONError.unexpectedEnd }
            if bytes[i] == 0x2C { i += 1; continue }
            if bytes[i] == 0x5D { i += 1; return .array(items) }
            throw StrictJSONError.unexpectedByte(offset: i)
        }
    }

    private mutating func parseString() throws -> String {
        i += 1 // opening quote
        var out: [UInt8] = []
        while true {
            guard i < bytes.count else { throw StrictJSONError.unexpectedEnd }
            let b = bytes[i]
            if b == 0x22 { i += 1; break }
            if b == 0x5C {
                i += 1
                guard i < bytes.count else { throw StrictJSONError.unexpectedEnd }
                switch bytes[i] {
                case 0x22: out.append(0x22)
                case 0x5C: out.append(0x5C)
                case 0x2F: out.append(0x2F)
                case 0x62: out.append(0x08)
                case 0x66: out.append(0x0C)
                case 0x6E: out.append(0x0A)
                case 0x72: out.append(0x0D)
                case 0x74: out.append(0x09)
                case 0x75:
                    let start = i - 1
                    var scalarValue = try parseHex4(at: i + 1)
                    i += 4
                    if (0xD800...0xDBFF).contains(scalarValue) {
                        // Expect a low surrogate escape.
                        guard i + 6 < bytes.count, bytes[i + 1] == 0x5C, bytes[i + 2] == 0x75 else { throw StrictJSONError.unpairedSurrogate(offset: start) }
                        let low = try parseHex4(at: i + 3)
                        guard (0xDC00...0xDFFF).contains(low) else { throw StrictJSONError.unpairedSurrogate(offset: start) }
                        scalarValue = 0x10000 + ((scalarValue - 0xD800) << 10) + (low - 0xDC00)
                        i += 6
                    } else if (0xDC00...0xDFFF).contains(scalarValue) {
                        throw StrictJSONError.unpairedSurrogate(offset: start)
                    }
                    guard let scalar = Unicode.Scalar(scalarValue) else { throw StrictJSONError.invalidEscape(offset: start) }
                    out.append(contentsOf: Array(String(scalar).utf8))
                default: throw StrictJSONError.invalidEscape(offset: i)
                }
                i += 1
                continue
            }
            if b < 0x20 { throw StrictJSONError.unexpectedByte(offset: i) }
            out.append(b)
            i += 1
            guard out.count <= limits.maximumStringBytes else { throw StrictJSONError.stringTooLong }
        }
        guard let s = String(validating: out, as: UTF8.self) else { throw StrictJSONError.invalidUTF8 }
        return s
    }

    private func parseHex4(at start: Int) throws -> UInt32 {
        guard start + 4 <= bytes.count else { throw StrictJSONError.unexpectedEnd }
        var v: UInt32 = 0
        for k in 0..<4 {
            let c = bytes[start + k]
            let d: UInt32
            switch c {
            case 0x30...0x39: d = UInt32(c - 0x30)
            case 0x41...0x46: d = UInt32(c - 0x41 + 10)
            case 0x61...0x66: d = UInt32(c - 0x61 + 10)
            default: throw StrictJSONError.invalidEscape(offset: start)
            }
            v = v * 16 + d
        }
        return v
    }
}
