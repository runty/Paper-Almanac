import AppKit
import SwiftUI

@main
struct DailyProof {
    @MainActor static func main() async throws {
        let dates = ["2026-10-31", "2026-11-06", "2026-11-11"]
        let pages = try await DayReader.load(dates)
        let args = Array(CommandLine.arguments.dropFirst())
        if args.count == 2, args[0] == "--export" {
            let directory = URL(fileURLWithPath: args[1], isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for page in pages {
                let renderer = ImageRenderer(content: PrintFace(day: page))
                renderer.scale = 3
                guard let cg = renderer.cgImage,
                      let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else {
                    throw ProofError.unavailable("Could not render \(page.date.label)")
                }
                try png.write(to: directory.appendingPathComponent(page.date.label + ".png"), options: .atomic)
                print("\(page.date.label) · \(page.recommended.lines) / \(page.avoided.lines)")
            }
            let pads = HStack(spacing: 0) {
                ForEach(pages, id: \.date) { DesktopPad(page: $0) }
            }.padding(.vertical, 6).background(Color(white: 0.89))
            let padRenderer = ImageRenderer(content: pads)
            padRenderer.scale = 2
            guard let plate = padRenderer.cgImage,
                  let proof = NSBitmapImageRep(cgImage: plate).representation(using: .png, properties: [:]) else {
                throw ProofError.unavailable("Could not render desktop pad comparison")
            }
            try proof.write(to: directory.appendingPathComponent("desktop-pads.png"), options: .atomic)
            return
        }
        guard args.isEmpty else { throw ProofError.unavailable("Usage: DailyProof [--export DIRECTORY]") }
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let window = NSWindow(contentRect: .init(x: 0, y: 0, width: 360, height: 480),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Tung Shing · Print Proof"
        window.contentView = NSHostingView(rootView: ProofViewer(pages: pages))
        window.isReleasedWhenClosed = false
        let observer = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification,
                                                              object: window, queue: .main) { _ in
            MainActor.assumeIsolated { NSApplication.shared.terminate(nil) }
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        app.activate()
        withExtendedLifetime((window, observer)) { app.run() }
    }
}

private struct ProofViewer: View {
    let pages: [PrintedDay]
    @State private var index = 0
    var body: some View {
        VStack(spacing: 0) {
            DesktopPad(page: pages[index])
            Picker("Reference date", selection: $index) {
                ForEach(pages.indices, id: \.self) { i in Text(verbatim: pages[i].date.label).tag(i) }
            }.labelsHidden().pickerStyle(.segmented).padding(10)
        }
    }
}
