// Typed issues, requirements, decisions and reports. Expected conditions are data, not thrown errors.

public enum InputField: String, Sendable, Hashable, CaseIterable, Comparable {
    case profile, gregorianYear, gregorianMonth, gregorianDay
    case lunarYear, lunarMonth, lunarLeapIdentity, lunarDay

    public static func < (lhs: InputField, rhs: InputField) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum IssueCode: String, Sendable, Hashable, Comparable {
    case needsObservation, invalidValue, unsupportedProfile
    case unsupportedCapability, sourceRestricted, unresolvedMethod
    case outsideAcceptedDomain, missingNeighbourEvent
    case uncertainCivilProjection, nonexistentLunarMonth, impossibleLunarDay
    case resourceUnavailable, invalidResource, failedPrerequisite
    /// The selected method has no defined result for this date: a known defect of its pinned source (the original
    /// almanac profile's 2032-02-04…10), not missing or invalid data.
    case methodUndefinedForDate

    public static func < (lhs: IssueCode, rhs: IssueCode) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum IssueRemedy: Sendable, Hashable {
    case supply(InputField)
    case chooseSupportedProfile
    case chooseAcceptedDate
    case installAcceptedResources
    case inspectEvidence
    case retry
}

public enum IssueSeverity: String, Sendable, Hashable { case warning, blocking }

public struct ContractIssue: Sendable, Hashable {
    public let contract: ContractID
    public let field: InputField?
    public let code: IssueCode
    public let severity: IssueSeverity
    public let remedies: [IssueRemedy]
    public let capability: CalendarCapability
    public let decisions: [DecisionID]
    public let evidence: [EvidenceID]

    public init(contract: ContractID, field: InputField?, code: IssueCode, severity: IssueSeverity,
                remedies: [IssueRemedy], capability: CalendarCapability, decisions: [DecisionID] = [], evidence: [EvidenceID] = []) {
        self.contract = contract
        self.field = field
        self.code = code
        self.severity = severity
        self.remedies = remedies
        self.capability = capability
        self.decisions = decisions
        self.evidence = evidence
    }
}

public enum RequirementState: String, Sendable, Hashable { case supplied, needsObservation, irrelevant, invalid }
public enum InputOrigin: String, Sendable, Hashable { case userObservation, methodFixed, provider, derived }

public enum FieldConstraint: Sendable, Hashable {
    case integer(minimum: Int64, maximum: Int64)
    case explicitBoolean
    case installedProfile
}

public struct FieldRequirement: Sendable, Hashable {
    public let field: InputField
    public let state: RequirementState
    public let origin: InputOrigin
    public let constraint: FieldConstraint
    public let contract: ContractID

    public init(field: InputField, state: RequirementState, origin: InputOrigin, constraint: FieldConstraint, contract: ContractID) {
        self.field = field
        self.state = state
        self.origin = origin
        self.constraint = constraint
        self.contract = contract
    }
}

public enum DecisionCategory: String, Sendable, Hashable { case methodSource, userChoice, appEngineering }

public struct ResolvedDecisionReference: Sendable, Hashable {
    public let identity: DecisionID
    public let category: DecisionCategory
    public let contract: ContractID
    public let selectedValueEvidence: EvidenceID

    public init(identity: DecisionID, category: DecisionCategory, contract: ContractID, selectedValueEvidence: EvidenceID) {
        self.identity = identity
        self.category = category
        self.contract = contract
        self.selectedValueEvidence = selectedValueEvidence
    }
}

public struct RequirementAssessment: Sendable, Hashable {
    public let revision: RequestRevision
    public let catalogue: CatalogueID
    public let fields: [FieldRequirement]
    public let fixedDecisions: [ResolvedDecisionReference]
    public let issues: [ContractIssue]

    public init(revision: RequestRevision, catalogue: CatalogueID, fields: [FieldRequirement],
                fixedDecisions: [ResolvedDecisionReference], issues: [ContractIssue]) {
        self.revision = revision
        self.catalogue = catalogue
        self.fields = fields
        self.fixedDecisions = fixedDecisions
        self.issues = issues
    }

    public var hasBlockingIssues: Bool { issues.contains { $0.severity == .blocking } }
}

public struct ValidationReport: Sendable, Hashable {
    public let original: CalendarRequestDraft
    public let revision: RequestRevision
    public let catalogue: CatalogueID
    public let locallyValidatedInput: LocallyValidatedInput?
    public let assessment: RequirementAssessment
    public let deferredResourceChecks: [ContractID]
    public let issues: [ContractIssue]

    public init(original: CalendarRequestDraft, revision: RequestRevision, catalogue: CatalogueID,
                locallyValidatedInput: LocallyValidatedInput?, assessment: RequirementAssessment,
                deferredResourceChecks: [ContractID], issues: [ContractIssue]) {
        self.original = original
        self.revision = revision
        self.catalogue = catalogue
        self.locallyValidatedInput = locallyValidatedInput
        self.assessment = assessment
        self.deferredResourceChecks = deferredResourceChecks
        self.issues = issues
    }

    public var hasBlockingIssues: Bool { issues.contains { $0.severity == .blocking } }
}
