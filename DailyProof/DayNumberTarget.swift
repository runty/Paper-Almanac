import SwiftUI

#if os(iOS)
struct DayNumberBounds: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        if let bounds = nextValue() { value = bounds }
    }
}
#endif

extension View {
    /// Mark the numeral before its surrounding column expands to fill the sheet.
    @ViewBuilder func dayNumberTarget() -> some View {
        #if os(iOS)
        anchorPreference(key: DayNumberBounds.self, value: .bounds) { $0 }
        #else
        self
        #endif
    }
}
