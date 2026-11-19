// Loads and validates one `tung-shing-calendar-events/v2` document into an immutable store.
// Validation order follows docs/design/E1_DATA_CONTRACT.md "Admission and limits".

import TungShingCore

public enum PackLoadError: Error, Sendable, Hashable {
    case json(StrictJSONError)
    case unexpectedFormat(String)
    case missingKey(String)
    case unexpectedKey(String)
    case wrongType(String)
    case invalidValue(String)
    case limitExceeded(String)
    case unsortedEvents(String)
    case danglingEvidence(String)
    case cyclicEvidence
    case digestMismatch(expected: String, actual: String)
    case core(CoreValidationError)
}

public struct PackLimits: Sendable, Hashable {
    public var maximumEvents = 25_000
    public var maximumEvidence = 100_000
    public var maximumDependenciesPerNode = 32
    public var maximumEdges = 500_000
    public var json = JSONLimits.packDefaults
    public init() {}
    public static let defaults = PackLimits()
}

public struct EventPackLoaderV2: EventPackLoader {
    public typealias Pack = EventPackStore
    public let limits: PackLimits
    public let formatContract: ContractID

    public init(limits: PackLimits = .defaults, formatContract: ContractID) {
        self.limits = limits
        self.formatContract = formatContract
    }

    /// Complete validation; the expected digest comes from the trusted installation manifest.
    @concurrent public func loadAndValidate(bytes: [UInt8], expected: PackID) async throws -> EventPackStore {
        try Self.load(bytes: bytes, expected: expected, limits: limits, formatContract: formatContract)
    }

    public static func load(bytes: [UInt8], expected: PackID?, limits: PackLimits = .defaults, formatContract: ContractID) throws -> EventPackStore {
        let root: CanonicalValue
        do { root = try StrictJSONParser.parse(bytes, limits: limits.json) } catch let e as StrictJSONError { throw PackLoadError.json(e) }
        let digest = try CanonicalJSON.digest(role: .pack, value: root)
        if let expected, expected.digest != digest { throw PackLoadError.digestMismatch(expected: expected.digest, actual: digest) }
        let packID = try PackID(digest: digest)
        return try decode(root, packID: packID, limits: limits, formatContract: formatContract)
    }

    // MARK: - Decoding helpers

    private static func object(_ v: CanonicalValue, _ path: String, allowed: Set<String>) throws -> [String: CanonicalValue] {
        guard case .object(let o) = v else { throw PackLoadError.wrongType(path) }
        for key in o.keys where !allowed.contains(key) { throw PackLoadError.unexpectedKey("\(path).\(key)") }
        for key in allowed where o[key] == nil { throw PackLoadError.missingKey("\(path).\(key)") }
        return o
    }

    private static func string(_ o: [String: CanonicalValue], _ key: String, _ path: String) throws -> String {
        guard case .string(let s)? = o[key] else { throw PackLoadError.wrongType("\(path).\(key)") }
        return s
    }

    private static func optionalString(_ o: [String: CanonicalValue], _ key: String, _ path: String) throws -> String? {
        switch o[key] {
        case .string(let s)?: return s
        case .null?: return nil
        default: throw PackLoadError.wrongType("\(path).\(key)")
        }
    }

    private static func array(_ o: [String: CanonicalValue], _ key: String, _ path: String) throws -> [CanonicalValue] {
        guard case .array(let a)? = o[key] else { throw PackLoadError.wrongType("\(path).\(key)") }
        return a
    }

    private static func strings(_ o: [String: CanonicalValue], _ key: String, _ path: String) throws -> [String] {
        try array(o, key, path).map { v in
            guard case .string(let s) = v else { throw PackLoadError.wrongType("\(path).\(key)[]") }
            return s
        }
    }

    private static func signed(_ s: String, _ path: String) throws -> Int64 {
        do { return try CanonicalJSON.validateSignedInteger(s) } catch { throw PackLoadError.invalidValue(path) }
    }

    private static func unsigned(_ s: String, _ path: String) throws -> UInt64 {
        do { return try CanonicalJSON.validateUnsignedInteger(s) } catch { throw PackLoadError.invalidValue(path) }
    }

    private static func date(_ v: CanonicalValue, _ path: String) throws -> GregorianDate {
        let o = try object(v, path, allowed: ["year", "month", "day"])
        let y = try signed(try string(o, "year", path), "\(path).year")
        let m = try unsigned(try string(o, "month", path), "\(path).month")
        let d = try unsigned(try string(o, "day", path), "\(path).day")
        do { return try GregorianDate(year: Int(y), month: Int(m), day: Int(d)) } catch let e as CoreValidationError { throw PackLoadError.core(e) }
    }

    private static func interval(_ v: CanonicalValue, _ path: String) throws -> CivilDateInterval {
        let o = try object(v, path, allowed: ["startInclusive", "endExclusive"])
        do {
            return try CivilDateInterval(startInclusive: try date(o["startInclusive"]!, "\(path).startInclusive"), endExclusive: try date(o["endExclusive"]!, "\(path).endExclusive"))
        } catch let e as CoreValidationError { throw PackLoadError.core(e) }
    }

    private static func domain(_ v: CanonicalValue, _ path: String) throws -> AcceptedDateDomain {
        guard case .array(let items) = v else { throw PackLoadError.wrongType(path) }
        let intervals = try items.enumerated().map { try interval($0.element, "\(path)[\($0.offset)]") }
        // Must already be sorted, nonoverlapping and coalesced.
        for i in 1..<max(1, intervals.count) where intervals.count > 1 {
            guard intervals[i].startInclusive > intervals[i - 1].endExclusive else { throw PackLoadError.invalidValue("\(path): intervals must be sorted, disjoint and coalesced") }
        }
        do { return try AcceptedDateDomain(intervals: intervals) } catch let e as CoreValidationError { throw PackLoadError.core(e) }
    }

    private static func instant(_ v: CanonicalValue, _ path: String) throws -> TTInstant {
        let o = try object(v, path, allowed: ["julianDay", "nanosecondsWithinDay"])
        let jd = try signed(try string(o, "julianDay", path), "\(path).julianDay")
        let ns = try signed(try string(o, "nanosecondsWithinDay", path), "\(path).nanosecondsWithinDay")
        do { return try TTInstant(julianDay: jd, nanosecondsWithinDay: ns) } catch let e as CoreValidationError { throw PackLoadError.core(e) }
    }

    private static func evidenceID(_ s: String, _ path: String) throws -> EvidenceID {
        do { return try EvidenceID(s) } catch let e as CoreValidationError { throw PackLoadError.core(e) }
    }

    // MARK: - Decoding

    private static func decode(_ root: CanonicalValue, packID: PackID, limits: PackLimits, formatContract: ContractID) throws -> EventPackStore {
        let o = try object(root, "root", allowed: ["format", "profile", "recipe", "coverage", "events", "evidence", "reuse"])
        let format = try string(o, "format", "root")
        guard format == formatContract.value else { throw PackLoadError.unexpectedFormat(format) }
        let profile: ProfileID
        do { profile = try ProfileID(try string(o, "profile", "root")) } catch let e as CoreValidationError { throw PackLoadError.core(e) }

        // Evidence graph first: ids, kinds, dependencies acyclic.
        let evidenceItems = try array(o, "evidence", "root")
        guard evidenceItems.count <= limits.maximumEvidence else { throw PackLoadError.limitExceeded("evidence") }
        var evidenceKinds: [EvidenceID: String] = [:]
        var dependencies: [EvidenceID: [EvidenceID]] = [:]
        var edgeCount = 0
        let allowedKinds: Set<String> = ["source", "model", "projection", "completeness", "derivation", "reuse", "independentFixture", "upstreamComparison", "syntheticFixture", "regression"]
        for (idx, item) in evidenceItems.enumerated() {
            let p = "root.evidence[\(idx)]"
            let e = try object(item, p, allowed: ["id", "kind", "sourceLocator", "sourceRevision", "contentDigest", "contract", "dependencies", "limitations"])
            let id = try evidenceID(try string(e, "id", p), p)
            guard evidenceKinds[id] == nil else { throw PackLoadError.invalidValue("\(p).id duplicate") }
            let kind = try string(e, "kind", p)
            guard allowedKinds.contains(kind) else { throw PackLoadError.invalidValue("\(p).kind") }
            _ = try string(e, "sourceLocator", p)
            _ = try string(e, "sourceRevision", p)
            _ = try optionalString(e, "contentDigest", p)
            _ = try optionalString(e, "contract", p)
            let deps = try strings(e, "dependencies", p).map { try evidenceID($0, "\(p).dependencies") }
            guard deps.count <= limits.maximumDependenciesPerNode else { throw PackLoadError.limitExceeded("\(p).dependencies") }
            edgeCount += deps.count
            guard edgeCount <= limits.maximumEdges else { throw PackLoadError.limitExceeded("edges") }
            _ = try strings(e, "limitations", p)
            evidenceKinds[id] = kind
            dependencies[id] = deps
        }
        for (id, deps) in dependencies {
            for d in deps where evidenceKinds[d] == nil { throw PackLoadError.danglingEvidence("\(id.value) -> \(d.value)") }
        }
        try assertAcyclic(dependencies)

        func requireEvidence(_ s: String, _ path: String) throws -> EvidenceID {
            let id = try evidenceID(s, path)
            guard evidenceKinds[id] != nil else { throw PackLoadError.danglingEvidence("\(path): \(s)") }
            return id
        }
        /// An ordered, non-empty list of evidence IDs that must all resolve.
        func requireEvidenceList(_ o: [String: CanonicalValue], _ key: String, _ path: String) throws -> [EvidenceID] {
            let ids = try strings(o, key, path).map { try requireEvidence($0, "\(path).\(key)") }
            guard !ids.isEmpty else { throw PackLoadError.invalidValue("\(path).\(key) empty") }
            return ids
        }

        // Recipe.
        let recipeObj = try object(o["recipe"]!, "root.recipe", allowed: ["generatorRepository", "generatorCommit", "generatorEntryPoint", "generatorParameters", "numericalInputs", "eventDefinitionContract", "frameContract", "timeScaleContract", "civilProjectionContract", "recipeEvidence"])
        var recipeSummary: [String: String] = [:]
        for key in ["generatorRepository", "generatorCommit", "generatorEntryPoint", "eventDefinitionContract", "frameContract", "timeScaleContract", "civilProjectionContract"] {
            recipeSummary[key] = try string(recipeObj, key, "root.recipe")
        }
        var paramNames = Set<String>()
        for (idx, p) in try array(recipeObj, "generatorParameters", "root.recipe").enumerated() {
            let po = try object(p, "root.recipe.generatorParameters[\(idx)]", allowed: ["name", "value"])
            let name = try string(po, "name", "root.recipe.generatorParameters[\(idx)]")
            guard paramNames.insert(name).inserted else { throw PackLoadError.invalidValue("duplicate generator parameter \(name)") }
            _ = try string(po, "value", "root.recipe.generatorParameters[\(idx)]")
        }
        for (idx, n) in try array(recipeObj, "numericalInputs", "root.recipe").enumerated() {
            let no = try object(n, "root.recipe.numericalInputs[\(idx)]", allowed: ["name", "sha256", "sourceEvidence"])
            _ = try string(no, "name", "root.recipe.numericalInputs[\(idx)]")
            let sha = try string(no, "sha256", "root.recipe.numericalInputs[\(idx)]")
            // Digest form of the contract: "sha256:" followed by 64 lowercase hex digits.
            do { _ = try PackID(digest: sha) } catch { throw PackLoadError.invalidValue("root.recipe.numericalInputs[\(idx)].sha256") }
            _ = try requireEvidence(try string(no, "sourceEvidence", "root.recipe.numericalInputs[\(idx)]"), "root.recipe.numericalInputs[\(idx)].sourceEvidence")
        }
        let recipeEvidence = try requireEvidenceList(recipeObj, "recipeEvidence", "root.recipe")
        let civilProjectionContract: ContractID
        do { civilProjectionContract = try ContractID(recipeSummary["civilProjectionContract"]!) } catch let e as CoreValidationError { throw PackLoadError.core(e) }

        // Coverage.
        let cov = try object(o["coverage"]!, "root.coverage", allowed: ["nominalOutputIntervals", "eventTTInterval", "dependencyIntervals", "excludedIntervals", "completenessEvidence"])
        let nominal = try domain(cov["nominalOutputIntervals"]!, "root.coverage.nominalOutputIntervals")
        let depIntervals = try domain(cov["dependencyIntervals"]!, "root.coverage.dependencyIntervals")
        let excluded = try domain(cov["excludedIntervals"]!, "root.coverage.excludedIntervals")
        // Half-open TT interval, named like the date intervals of the contract.
        let tt = try object(cov["eventTTInterval"]!, "root.coverage.eventTTInterval", allowed: ["startInclusive", "endExclusive"])
        let ttLower = try instant(tt["startInclusive"]!, "root.coverage.eventTTInterval.startInclusive")
        let ttUpper = try instant(tt["endExclusive"]!, "root.coverage.eventTTInterval.endExclusive")
        guard ttLower < ttUpper else { throw PackLoadError.invalidValue("root.coverage.eventTTInterval") }
        let completeness = try requireEvidenceList(cov, "completenessEvidence", "root.coverage")

        // Reuse.
        var permission: SourcePermissionStatus = .unresolved
        var restrictedEvidence: [EvidenceID] = []
        for (idx, r) in try array(o, "reuse", "root").enumerated() {
            let ro = try object(r, "root.reuse[\(idx)]", allowed: ["sourceEvidence", "status", "uses", "noticeLocators", "reviewEvidence"])
            let src = try requireEvidence(try string(ro, "sourceEvidence", "root.reuse[\(idx)]"), "root.reuse[\(idx)].sourceEvidence")
            let status = try string(ro, "status", "root.reuse[\(idx)]")
            guard ["unresolved", "restricted", "permitted"].contains(status) else { throw PackLoadError.invalidValue("root.reuse[\(idx)].status") }
            _ = try strings(ro, "uses", "root.reuse[\(idx)]")
            _ = try strings(ro, "noticeLocators", "root.reuse[\(idx)]")
            _ = try strings(ro, "reviewEvidence", "root.reuse[\(idx)]").map { try requireEvidence($0, "root.reuse[\(idx)].reviewEvidence") }
            if status == "restricted" { restrictedEvidence.append(src) }
        }
        if !restrictedEvidence.isEmpty { permission = .restricted(evidence: restrictedEvidence) }

        // Events.
        let eventItems = try array(o, "events", "root")
        guard eventItems.count <= limits.maximumEvents else { throw PackLoadError.limitExceeded("events") }
        var events: [CalendarEvent] = []
        events.reserveCapacity(eventItems.count)
        var seenIDs = Set<EvidenceID>()
        var projectionPolicies = Set<ContractID>()
        var lastConjunctionTT: TTInstant? = nil
        var lastConjunctionDate: GregorianDate? = nil
        var lastTerm: (TTInstant, Int)? = nil
        var previousKey: (TTInstant, CalendarEventKind)? = nil
        var scenarioDates: [EvidenceID: [String: [GregorianDate]]] = [:]
        for (idx, item) in eventItems.enumerated() {
            let p = "root.events[\(idx)]"
            let e = try object(item, p, allowed: ["id", "kind", "termIndex", "tt", "rootBracket", "numericalResolutionNS", "astronomicalUncertaintyEvidence", "projection", "sourceEvidence"])
            let id = try evidenceID(try string(e, "id", p), p)
            guard seenIDs.insert(id).inserted else { throw PackLoadError.invalidValue("\(p).id duplicate") }
            let kindString = try string(e, "kind", p)
            let kind: CalendarEventKind
            switch kindString {
            case "conjunction":
                guard case .null? = e["termIndex"] else { throw PackLoadError.invalidValue("\(p).termIndex must be null") }
                kind = .conjunction
            case "solarTerm":
                let idxValue = try unsigned(try string(e, "termIndex", p), "\(p).termIndex")
                do { kind = try CalendarEventKind.solarTerm(validating: Int(idxValue)) } catch let err as CoreValidationError { throw PackLoadError.core(err) }
            default:
                throw PackLoadError.invalidValue("\(p).kind")
            }
            let nominal = try instant(e["tt"]!, "\(p).tt")
            let bo = try object(e["rootBracket"]!, "\(p).rootBracket", allowed: ["lowerInclusive", "upperInclusive"])
            let bracket: TTEventBracket
            do { bracket = try TTEventBracket(lowerInclusive: try instant(bo["lowerInclusive"]!, "\(p).rootBracket.lowerInclusive"), upperInclusive: try instant(bo["upperInclusive"]!, "\(p).rootBracket.upperInclusive")) } catch let err as CoreValidationError { throw PackLoadError.core(err) }
            let resolution = try unsigned(try string(e, "numericalResolutionNS", p), "\(p).numericalResolutionNS")
            guard resolution > 0 else { throw PackLoadError.invalidValue("\(p).numericalResolutionNS") }
            let uncertainty = try requireEvidenceList(e, "astronomicalUncertaintyEvidence", p)
            _ = try strings(e, "sourceEvidence", p).map { try requireEvidence($0, "\(p).sourceEvidence") }

            // Projection.
            let pr = try object(e["projection"]!, "\(p).projection", allowed: ["state", "dates", "basis", "policyContract", "mappingEvidence", "assumptions", "reason", "scenarioDates"])
            let state = try string(pr, "state", "\(p).projection")
            let dates = try array(pr, "dates", "\(p).projection").enumerated().map { try date($0.element, "\(p).projection.dates[\($0.offset)]") }
            for i in 1..<max(1, dates.count) where dates.count > 1 { guard dates[i] > dates[i - 1] else { throw PackLoadError.invalidValue("\(p).projection.dates must be sorted unique") } }
            let mapping = try requireEvidenceList(pr, "mappingEvidence", "\(p).projection")
            // The date of each named scenario where they disagree; their union is the ambiguous date list.
            switch pr["scenarioDates"] {
            case .null?:
                break
            case .object(let scenarios)?:
                var named: [String: [GregorianDate]] = [:]
                var union = Set<GregorianDate>()
                for (name, value) in scenarios {
                    guard case .array(let items) = value, !items.isEmpty else { throw PackLoadError.invalidValue("\(p).projection.scenarioDates.\(name)") }
                    let ds = try items.enumerated().map { try date($0.element, "\(p).projection.scenarioDates.\(name)[\($0.offset)]") }
                    named[name] = ds
                    union.formUnion(ds)
                }
                guard union == Set(dates), named.count >= 2 else { throw PackLoadError.invalidValue("\(p).projection.scenarioDates union") }
                scenarioDates[id] = named
            default:
                throw PackLoadError.wrongType("\(p).projection.scenarioDates")
            }
            let assumptions = try strings(pr, "assumptions", "\(p).projection").map { try requireEvidence($0, "\(p).projection.assumptions") }
            let basisString = try optionalString(pr, "basis", "\(p).projection")
            let policyString = try optionalString(pr, "policyContract", "\(p).projection")
            let reasonString = try optionalString(pr, "reason", "\(p).projection")
            let projection: HKCivilDateProjection
            switch state {
            case "definite":
                guard dates.count == 1, reasonString == nil else { throw PackLoadError.invalidValue("\(p).projection definite shape") }
                let basis: ProjectionBasis
                switch basisString {
                case "modeled":
                    guard let policyString else { throw PackLoadError.invalidValue("\(p).projection.policyContract") }
                    let policy: ContractID
                    do { policy = try ContractID(policyString) } catch let err as CoreValidationError { throw PackLoadError.core(err) }
                    projectionPolicies.insert(policy)
                    basis = .modeled(policy: policy, assumptions: assumptions)
                case "authoritativePublication":
                    basis = .authoritativePublication(source: mapping[0])
                default:
                    throw PackLoadError.invalidValue("\(p).projection.basis")
                }
                projection = .definite(dates[0], basis: basis, mappingEvidence: mapping)
            case "ambiguous":
                guard dates.count >= 2, reasonString == nil else { throw PackLoadError.invalidValue("\(p).projection ambiguous shape") }
                if let policyString { do { projectionPolicies.insert(try ContractID(policyString)) } catch let err as CoreValidationError { throw PackLoadError.core(err) } }
                projection = .ambiguous(dates, mappingEvidence: mapping)
            case "unavailable":
                guard dates.isEmpty, let reasonString, let code = IssueCode(rawValue: reasonString) else { throw PackLoadError.invalidValue("\(p).projection unavailable shape") }
                projection = .unavailable(reason: ContractIssue(contract: civilProjectionContract, field: nil, code: code, severity: .blocking, remedies: [.inspectEvidence], capability: .hkCalendarIdentity, evidence: mapping))
            default:
                throw PackLoadError.invalidValue("\(p).projection.state")
            }

            // Ordering and progression invariants.
            if let prev = previousKey {
                guard (prev.0, prev.1) < (nominal, kind) else { throw PackLoadError.unsortedEvents(p) }
            }
            previousKey = (nominal, kind)
            switch kind {
            case .conjunction:
                if let last = lastConjunctionTT { guard nominal > last else { throw PackLoadError.unsortedEvents("\(p) conjunction TT") } }
                lastConjunctionTT = nominal
                if case .definite(let d, _, _) = projection {
                    if let lastDate = lastConjunctionDate { guard d > lastDate else { throw PackLoadError.unsortedEvents("\(p) conjunction date") } }
                    lastConjunctionDate = d
                }
            case .solarTerm(let i):
                if let (lastTT, lastIndex) = lastTerm {
                    guard nominal > lastTT, Int(i) == (lastIndex + 1) % 24 else { throw PackLoadError.unsortedEvents("\(p) term progression") }
                }
                lastTerm = (nominal, Int(i))
            }

            guard bracket.encloses(nominal) else { throw PackLoadError.invalidValue("\(p).tt outside rootBracket") }
            if case .ambiguous = projection { guard scenarioDates[id] != nil else { throw PackLoadError.invalidValue("\(p).projection.scenarioDates missing") } }
            let event: CalendarEvent
            do {
                event = try CalendarEvent(identity: id, kind: kind, nominalTT: nominal, rootBracket: bracket, astronomicalUncertaintyEvidence: uncertainty, hkProjection: projection)
            } catch let err as CoreValidationError { throw PackLoadError.core(err) }
            events.append(event)
        }
        guard events.count >= 2 else { throw PackLoadError.invalidValue("root.events too few") }

        let descriptor = PackDescriptor(
            identity: packID, profile: profile, formatContract: formatContract,
            manifestEvidence: recipeEvidence[0], providerEvidence: recipeEvidence[0], dynamicsToCivilEvidence: completeness[0],
            sourcePermission: permission, verification: .notAssessed, acceptedDomain: .empty)
        let coverage = PackCoverage(nominalOutputIntervals: nominal, dependencyIntervals: depIntervals, excludedIntervals: excluded, eventTTInterval: (ttLower, ttUpper))
        return EventPackStore(descriptor: descriptor, coverage: coverage, events: events, completenessEvidence: completeness, projectionPolicies: projectionPolicies,
                              recipeSummary: recipeSummary, scenarioDates: scenarioDates)
    }

    private static func assertAcyclic(_ graph: [EvidenceID: [EvidenceID]]) throws {
        var state: [EvidenceID: Int] = [:] // 1 visiting, 2 done
        func visit(_ node: EvidenceID) throws {
            if state[node] == 2 { return }
            if state[node] == 1 { throw PackLoadError.cyclicEvidence }
            state[node] = 1
            for d in graph[node] ?? [] { try visit(d) }
            state[node] = 2
        }
        for node in graph.keys { try visit(node) }
    }
}
