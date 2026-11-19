// Client request drafts and their validated forms. Drafts may be incomplete so forms can
// preserve observations; validation reports what is missing or wrong.

public enum DateInputDraft: Sendable, Hashable {
    case gregorian(year: Int?, month: Int?, day: Int?)
    /// Lunar entry requires an explicit leap flag; nil means "not yet answered".
    case lunar(year: Int?, month: Int?, isLeapMonth: Bool?, day: Int?)
}

public enum CalendarOperationDraft: Sendable, Hashable {
    case dateIdentity(DateInputDraft)
    case convert(DateInputDraft)
    case gregorianMonth(year: Int?, month: Int?)
}

public enum ValidatedDateInput: Sendable, Hashable {
    case gregorian(GregorianDate)
    case lunar(LunarDate)
}

public enum LocallyValidatedInput: Sendable, Hashable {
    case date(ValidatedDateInput)
    case month(GregorianYearMonth)
}

public struct CalendarRequestDraft: Sendable, Hashable {
    public let revision: RequestRevision
    public let profile: ProfileID
    public let operation: CalendarOperationDraft

    public init(revision: RequestRevision, profile: ProfileID, operation: CalendarOperationDraft) {
        self.revision = revision
        self.profile = profile
        self.operation = operation
    }
}

/// Checked construction of request inputs for clients.
public protocol CalendarInputFactory: Sendable {
    func revision(validating value: String) throws -> RequestRevision
    func gregorianDate(year: Int, month: Int, day: Int) throws -> GregorianDate
    func lunarDate(year: Int, month: Int, isLeapMonth: Bool, day: Int) throws -> LunarDate
    func request(revision: RequestRevision, profile: ProfileID, operation: CalendarOperationDraft) -> CalendarRequestDraft
}

public struct StandardInputFactory: CalendarInputFactory {
    public init() {}
    public func revision(validating value: String) throws -> RequestRevision { try RequestRevision(value) }
    public func gregorianDate(year: Int, month: Int, day: Int) throws -> GregorianDate { try GregorianDate(year: year, month: month, day: day) }
    public func lunarDate(year: Int, month: Int, isLeapMonth: Bool, day: Int) throws -> LunarDate {
        try LunarDate(lunarYearStartingGregorianYear: year, month: month, isLeapMonth: isLeapMonth, day: day)
    }
    public func request(revision: RequestRevision, profile: ProfileID, operation: CalendarOperationDraft) -> CalendarRequestDraft {
        CalendarRequestDraft(revision: revision, profile: profile, operation: operation)
    }
}
