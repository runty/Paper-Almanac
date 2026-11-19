// Exact Python value semantics needed by the port: floor arithmetic, code-point string
// indexing/slicing, and the `needle in container` membership test used by the rule loop
// (lunar.py:1030). Upstream mixes substring tests (container is a `str`) with element
// equality tests (container is a `list`/`tuple`/`range`); both are reproduced here.

/// Python-style floor modulo: the result has the sign of the divisor.
@inlinable
func floorMod(_ a: Int, _ m: Int) -> Int {
    let r = a % m
    return r < 0 ? r + m : r
}

/// Python-style floor division.
@inlinable
func floorDiv(_ a: Int, _ b: Int) -> Int {
    let q = a / b
    return (a % b != 0 && ((a < 0) != (b < 0))) ? q - 1 : q
}

/// Python `str` helpers over Unicode scalars (Python strings index by code point).
enum PyString {
    /// `s[i]` with Python negative-index wrapping. Returns nil when out of range (IndexError).
    static func char(_ s: String, _ i: Int) -> String? {
        let scalars = Array(s.unicodeScalars)
        let idx = i < 0 ? scalars.count + i : i
        guard idx >= 0, idx < scalars.count else { return nil }
        return String(scalars[idx])
    }

    /// `s[a:b]` with non-negative bounds (clamped like Python).
    static func slice(_ s: String, _ a: Int, _ b: Int) -> String {
        let scalars = Array(s.unicodeScalars)
        let lo = max(0, min(a, scalars.count))
        let hi = max(lo, min(b, scalars.count))
        var out = String.UnicodeScalarView()
        out.append(contentsOf: scalars[lo..<hi])
        return String(out)
    }

    /// `s[:n]`.
    static func prefix(_ s: String, _ n: Int) -> String { slice(s, 0, n) }

    /// Python substring containment `needle in haystack` by code points (empty needle matches).
    static func contains(_ haystack: String, _ needle: String) -> Bool {
        let h = Array(haystack.unicodeScalars)
        let n = Array(needle.unicodeScalars)
        if n.isEmpty { return true }
        if n.count > h.count { return false }
        var i = 0
        while i + n.count <= h.count {
            if h[i..<(i + n.count)].elementsEqual(n) { return true }
            i += 1
        }
        return false
    }

    /// Number of code points.
    static func length(_ s: String) -> Int { s.unicodeScalars.count }
}

/// The left operand of an upstream `tuple[1] in tuple[2]` test, keeping its Python type.
public enum RuleOperand: Sendable, Hashable {
    /// A `str` (one character or a two-character pillar).
    case text(String)
    /// An `int`.
    case integer(Int)
    /// A `bool`.
    case boolean(Bool)
    /// A `(month, day)` tuple.
    case monthDay(month: Int, day: Int)
    /// A `(lunarMonth, dayPillar)` tuple.
    case monthPillar(month: Int, pillar: String)
    /// The upstream operand could not be reconstructed from the bounded term window; the
    /// membership test is provably false (documented in PHASE_2_ALMANAC.md).
    case absent
}

/// The right operand of an upstream membership test, keeping its Python container type.
public enum RuleContainer: Sendable, Hashable {
    /// A `str`: membership is substring containment.
    case text(String)
    /// A `list`/`tuple`: membership is element equality.
    case elements([RuleOperand])
    /// A `range(lower, upperExclusive)`.
    case integerRange(lower: Int, upperExclusive: Int)
}

enum PyMembership {
    /// Evaluates Python `needle in container` for the operand kinds that occur upstream.
    static func contains(_ needle: RuleOperand, _ container: RuleContainer) -> Bool {
        switch (needle, container) {
        case (.absent, _):
            return false
        case (.text(let n), .text(let h)):
            return PyString.contains(h, n)
        case (_, .text):
            // Python would raise TypeError for a non-str needle in a str; never reached by the port.
            return false
        case (.integer(let v), .integerRange(let lo, let hi)):
            return v >= lo && v < hi
        case (_, .integerRange):
            return false
        case (let n, .elements(let items)):
            return items.contains(n)
        }
    }
}
