import CoreText
import SwiftUI

/// The ink and its offset keyline share one silhouette, including on transparent widgets.
struct TungShingNumeral: View {
    let day: Int
    let size: CGFloat

    private static let printSize: CGFloat = 207
    private final class FontBundle {}

    private static let figures: [Int: Path] = {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: FontBundle.self)
        #endif
        guard let url = bundle.url(forResource: "Taviraj-Medium", withExtension: "ttf"),
              let provider = CGDataProvider(url: url as CFURL),
              let face = CGFont(provider) else {
            assertionFailure("Missing bundled Taviraj Medium")
            return [:]
        }
        let font = CTFontCreateWithGraphicsFont(face, printSize, nil, nil)
        let digits: [Path] = (0...9).map { digit in
            var character = UniChar(48 + digit)
            var glyph = CGGlyph()
            CTFontGetGlyphsForCharacters(font, &character, &glyph, 1)
            let outline = CTFontCreatePathForGlyph(font, glyph, nil)!
            return Path(outline).applying(CGAffineTransform(scaleX: 1, y: -1))
        }
        return Dictionary(uniqueKeysWithValues: (1...31).map { day in
            var face = digits[day % 10]
            if day >= 10 {
                let first = digits[day / 10]
                // Visible edge-to-edge gaps measured on the approved 207-point specimen.
                let gap: CGFloat = day == 31 ? 9.5 : day == 11 ? 11 : 10.4
                face = face.offsetBy(dx: first.boundingRect.maxX + gap - face.boundingRect.minX, dy: 0)
                face.addPath(first)
            }
            let bounds = face.boundingRect
            face = face.offsetBy(dx: -bounds.minX, dy: -bounds.minY)
            let keyline = face.offsetBy(dx: 4.3, dy: 3.35)
                .subtracting(face.offsetBy(dx: 2.85, dy: 2.05))
            return (day, face.union(keyline))
        })
    }()

    @ViewBuilder var body: some View {
        if let figure = Self.figures[day] {
            let scale = size / Self.printSize
            let bounds = figure.boundingRect
            figure.applying(CGAffineTransform(scaleX: scale, y: scale))
                .fill()
                .frame(width: bounds.width * scale, height: bounds.height * scale)
                .accessibilityLabel(Text(verbatim: String(day)))
        } else {
            Text(verbatim: String(day)).font(.system(size: size, design: .serif))
        }
    }
}
