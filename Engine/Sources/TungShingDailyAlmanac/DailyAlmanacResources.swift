import CryptoKit
import Foundation
import TungShingData
import TungShingAlmanac
import TungShingCore

struct DailyAlmanacResources: Sendable {
    // These are the admitted contracts' pins, tested against TungShingCatalog. Keeping this small
    // product independent of Catalog avoids bundling the full capability registry for a daily pad.
    static let runtimeSHA256 = "ddf89a6787fd12401a0ba5e515869e58d2686d8970db826dcf783a7d2b2ad907"
    static let contextSHA256 = "7021dbde2d23d844af80a150a6c7c6436fd10f45644b90e6ebace3e343f142f8"
    static let differencesSHA256 = "0eb390a0acd1cede1016837a90e82fa85abbe6dfb2840dad0cdbd75fe5b05ab2"

    let provider: Calendar2100Provider
    let terms: [TungShingAlmanac.SolarTermDate]
    let comparisons: [GregorianDate: DailyAlmanacSourceComparison]

    static let notice: String = {
        guard let url = Bundle.module.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return text
    }()

    static func data(_ name: String) -> Data? {
        Bundle.module.url(forResource: name, withExtension: "json").flatMap { try? Data(contentsOf: $0) }
    }

    static let bundled: Result<Self, Calendar2100Provider.LoadError> = {
        do throws(Calendar2100Provider.LoadError) {
            guard let runtime = data("calendar-1901-2100-runtime"), let context = data("calendar-1901-2100-context-terms"),
                  let differences = data("almanac-1901-2100-differences"), notice.contains("MIT License") else {
                throw .malformed("missing daily resource or notice")
            }
            return .success(try Self(runtime: runtime, context: context, differences: differences))
        } catch { return .failure(error) }
    }()

    init(runtime: Data, context: Data, differences: Data) throws(Calendar2100Provider.LoadError) {
        provider = try Calendar2100Provider(runtime: runtime, context: context, runtimeSHA256: Self.runtimeSHA256, contextSHA256: Self.contextSHA256)
        do { terms = try provider.termDays.map { try TungShingAlmanac.SolarTermDate(indexFromMarchEquinox: $0.index, date: $0.date) } }
        catch { throw .malformed("term context") }
        guard SHA256.hash(data: differences).map({ String(format: "%02x", $0) }).joined() == Self.differencesSHA256 else { throw .digest("differences") }
        guard let root = (try? JSONSerialization.jsonObject(with: differences)) as? [String: Any],
              let rows = root["correctedSourceDifferences"] as? [[String: Any]],
              let unavailable = root["correctedSourceUnavailableDates"] as? [String] else { throw .malformed("differences") }
        var values: [GregorianDate: DailyAlmanacSourceComparison] = [:]
        for row in rows {
            guard let label = row["date"] as? String, let date = try? GregorianDate(label: label),
                  let cause = row["cause"] as? String,
                  let value = DailyAlmanacSourceComparison(rawValue: "differs-" + cause.replacingOccurrences(of: "source-", with: "")) else {
                throw .malformed("difference row")
            }
            values[date] = value
        }
        for label in unavailable {
            guard let date = try? GregorianDate(label: label) else { throw .malformed("unavailable date") }
            values[date] = .sourceUnavailable
        }
        comparisons = values
    }
}
