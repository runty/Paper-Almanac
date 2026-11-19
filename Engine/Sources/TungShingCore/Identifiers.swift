// Stable identifiers used across the engine. Semantic identifiers are restricted to
// ASCII [A-Za-z0-9._:/-] and at most 256 bytes (E1 data contract); digests are
// "sha256:" plus 64 lowercase hexadecimal characters. Every initializer validates.

/// Errors raised by checked value construction anywhere in TungShingCore.
public enum CoreValidationError: Error, Sendable, Hashable {
    case invalidIdentifier(String)
    case invalidDigest(String)
    case invalidGregorianDate(year: Int, month: Int, day: Int)
    case invalidLunarComponents(year: Int, month: Int, day: Int)
    case invalidInterval
    case invalidInstant(julianDay: Int64, nanoseconds: Int64)
    case invalidBracket
    case invalidTermIndex(Int)
    case yearOutOfDomain(Int)
    case arithmeticOverflow
}

@usableFromInline
enum IdentifierRules {
    static let maximumBytes = 256

    static func validateSemantic(_ value: String) throws {
        guard !value.isEmpty, value.utf8.count <= maximumBytes else {
            throw CoreValidationError.invalidIdentifier(value)
        }
        for byte in value.utf8 {
            switch byte {
            case 0x30...0x39, 0x41...0x5A, 0x61...0x7A, 0x2E, 0x5F, 0x3A, 0x2F, 0x2D:
                continue
            default:
                throw CoreValidationError.invalidIdentifier(value)
            }
        }
    }

    static func validateDigest(_ value: String) throws {
        let prefix = "sha256:"
        guard value.hasPrefix(prefix) else { throw CoreValidationError.invalidDigest(value) }
        let hex = value.dropFirst(prefix.count)
        guard hex.utf8.count == 64 else { throw CoreValidationError.invalidDigest(value) }
        for byte in hex.utf8 {
            switch byte {
            case 0x30...0x39, 0x61...0x66: continue
            default: throw CoreValidationError.invalidDigest(value)
            }
        }
    }
}

public struct ProfileID: Sendable, Hashable, Comparable {
    public let value: String
    public init(_ value: String) throws { try IdentifierRules.validateSemantic(value); self.value = value }
    public static func < (lhs: ProfileID, rhs: ProfileID) -> Bool { lhs.value < rhs.value }
}

public struct ContractID: Sendable, Hashable, Comparable {
    public let value: String
    public init(_ value: String) throws { try IdentifierRules.validateSemantic(value); self.value = value }
    public static func < (lhs: ContractID, rhs: ContractID) -> Bool { lhs.value < rhs.value }
}

public struct DecisionID: Sendable, Hashable, Comparable {
    public let value: String
    public init(_ value: String) throws { try IdentifierRules.validateSemantic(value); self.value = value }
    public static func < (lhs: DecisionID, rhs: DecisionID) -> Bool { lhs.value < rhs.value }
}

public struct EvidenceID: Sendable, Hashable, Comparable {
    public let value: String
    public init(_ value: String) throws { try IdentifierRules.validateSemantic(value); self.value = value }
    public static func < (lhs: EvidenceID, rhs: EvidenceID) -> Bool { lhs.value < rhs.value }
}

/// A client-chosen request revision token; opaque to the engine, echoed back in reports.
public struct RequestRevision: Sendable, Hashable {
    public let value: String
    public init(_ value: String) throws { try IdentifierRules.validateSemantic(value); self.value = value }
}

/// Digest wrappers carry a role; the role is part of the hash input (see CanonicalJSON).
public struct PackID: Sendable, Hashable, Comparable {
    public let digest: String
    public init(digest: String) throws { try IdentifierRules.validateDigest(digest); self.digest = digest }
    public static func < (lhs: PackID, rhs: PackID) -> Bool { lhs.digest < rhs.digest }
}

public struct CatalogueID: Sendable, Hashable {
    public let digest: String
    public init(digest: String) throws { try IdentifierRules.validateDigest(digest); self.digest = digest }
}

public struct CalculationID: Sendable, Hashable {
    public let digest: String
    public init(digest: String) throws { try IdentifierRules.validateDigest(digest); self.digest = digest }
}

public struct ResultID: Sendable, Hashable {
    public let digest: String
    public init(digest: String) throws { try IdentifierRules.validateDigest(digest); self.digest = digest }
}
