import SwiftUI

extension ActivityPreference.Side: Identifiable {
    var id: Self { self }
    var title: String { self == .recommended ? "宜 · Do" : "忌 · Avoid" }
}

extension EnvironmentValues {
    @Entry var activityListSelection: Binding<ActivityPreference.Side?>?
}

private struct ActivityLink: ViewModifier {
    @Environment(\.activityListSelection) private var selection
    let side: ActivityPreference.Side

    @ViewBuilder func body(content: Content) -> some View {
        if let selection {
            Button { selection.wrappedValue = side } label: {
                content.contentShape(.interaction, Rectangle())
            }
            #if os(iOS)
            .buttonStyle(ActivityTapStyle())
            #else
            .buttonStyle(.plain)
            #endif
            .accessibilityHint("Show all " + side.rawValue + " activities")
        } else {
            content
        }
    }
}

#if os(iOS)
// A drag can begin and end inside a wide activity column. Only an actual
// tap opens it, leaving the whole column available to the paper gesture.
private struct ActivityTapStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onTapGesture { configuration.trigger() }
            .accessibilityAction { configuration.trigger() }
    }
}
#endif

extension View {
    func activityLink(side: ActivityPreference.Side) -> some View {
        modifier(ActivityLink(side: side))
    }
}
