// Dragging the pad around the desk by its binding.

import SwiftUI

extension View {
    func windowDragHandle() -> some View {
        gesture(WindowDragGesture())
    }
}
