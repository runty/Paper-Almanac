// Restricted canonical JSON, version 1, and domain-separated SHA-256 identities.
// See docs/design/E1_DATA_CONTRACT.md "Canonical encoding and identities".

import CryptoKit

/// A canonical value. JSON numeric literals are forbidden: numeric fields are decimal strings.
public indirect enum CanonicalValue: Sendable, Hashable {
    case object([String: CanonicalValue])
    case array([CanonicalValue])
    case string(String)
    case bool(Bool)
    case null
}

public enum CanonicalEncodingError: Error, Sendable, Equatable {
    case nonASCIIKey(String)
    case invalidIdentifier(String)
    case invalidNumeric(String)
}

public enum CanonicalJSON {
    public static let version = "v1"

    /// Encodes with keys sorted by byte order, no whitespace, minimal escapes.
    public static func encode(_ value: CanonicalValue) throws -> [UInt8] {
        var out: [UInt8] = []
        try write(value, into: &out)
        return out
    }

    private static func write(_ value: CanonicalValue, into out: inout [UInt8]) throws {
        switch value {
        case .null:
            out.append(contentsOf: Array("null".utf8))
        case .bool(let b):
            out.append(contentsOf: Array((b ? "true" : "false").utf8))
        case .string(let s):
            try writeString(s, into: &out)
        case .array(let items):
            out.append(0x5B)
            for (i, item) in items.enumerated() {
                if i > 0 { out.append(0x2C) }
                try write(item, into: &out)
            }
            out.append(0x5D)
        case .object(let dict):
            out.append(0x7B)
            // Sort by UTF-8 byte order.
            let keys = dict.keys.sorted { Array($0.utf8).lexicographicallyPrecedes(Array($1.utf8)) }
            for (i, key) in keys.enumerated() {
                guard key.utf8.allSatisfy({ $0 < 0x80 }) else { throw CanonicalEncodingError.nonASCIIKey(key) }
                if i > 0 { out.append(0x2C) }
                try writeString(key, into: &out)
                out.append(0x3A)
                try write(dict[key]!, into: &out)
            }
            out.append(0x7D)
        }
    }

    private static func writeString(_ s: String, into out: inout [UInt8]) throws {
        out.append(0x22)
        for scalar in s.unicodeScalars {
            switch scalar.value {
            case 0x22: out.append(contentsOf: [0x5C, 0x22])
            case 0x5C: out.append(contentsOf: [0x5C, 0x5C])
            case 0x00...0x1F:
                let hex = String(scalar.value, radix: 16)
                let padded = String(repeating: "0", count: 4 - hex.count) + hex
                out.append(contentsOf: Array("\\u\(padded)".utf8))
            default:
                out.append(contentsOf: Array(String(scalar).utf8))
            }
        }
        out.append(0x22)
    }

    /// Validates a signed-integer decimal string: 0 | -?[1-9][0-9]*
    public static func validateSignedInteger(_ s: String) throws -> Int64 {
        guard let v = Int64(s), String(v) == s else { throw CanonicalEncodingError.invalidNumeric(s) }
        return v
    }

    /// Validates an unsigned-integer decimal string: 0 | [1-9][0-9]*
    public static func validateUnsignedInteger(_ s: String) throws -> UInt64 {
        guard let v = UInt64(s), String(v) == s else { throw CanonicalEncodingError.invalidNumeric(s) }
        return v
    }

    public enum DigestRole: String, Sendable { case pack, catalogue, input, calculation, result, almanacProfile, baZiProfile, yijingProfile, liuyaoProfile, meihuaProfile }

    /// SHA-256 over "TS-E1" NUL role NUL "v1" NUL canonicalBytes, as "sha256:" + 64 lowercase hex.
    public static func digest(role: DigestRole, canonicalBytes: [UInt8]) -> String {
        var hasher = SHA256()
        hasher.update(data: Array("TS-E1".utf8) + [0] + Array(role.rawValue.utf8) + [0] + Array(version.utf8) + [0])
        hasher.update(data: canonicalBytes)
        let hex = hasher.finalize().map { byte -> String in
            let s = String(byte, radix: 16)
            return s.count == 1 ? "0" + s : s
        }.joined()
        return "sha256:" + hex
    }

    public static func digest(role: DigestRole, value: CanonicalValue) throws -> String {
        digest(role: role, canonicalBytes: try encode(value))
    }
}
