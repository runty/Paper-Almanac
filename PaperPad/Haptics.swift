//
//  Haptics.swift
//  himekuri
//
//  Trackpad haptics for the tear.
//

#if os(macOS)
import AppKit

enum Haptics {
    /// Small tick while the paper stretches.
    static func tick() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    /// The moment the page lets go.
    static func rip() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
}
#else
import UIKit

@MainActor enum Haptics {
    private static let fibers = UIImpactFeedbackGenerator(style: .light)
    private static let release = UIImpactFeedbackGenerator(style: .medium)
    static func tick() { fibers.impactOccurred(intensity: 0.45) }
    static func rip() { release.impactOccurred() }
}
#endif
