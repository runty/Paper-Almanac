//
//  Snapshot.swift
//  himekuri
//
//  Printing a SwiftUI page into a bitmap the paper solver can warp.
//

import SwiftUI

@MainActor
enum Snapshot {
    /// Renders the printed page at its natural size into a bitmap.
    static func cgImage<V: View>(of view: V, scale: CGFloat) -> CGImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.cgImage
    }
}
