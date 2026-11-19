import SwiftUI

struct MoonFace: View {
    let reading: MoonReading
    var widget = false
    static let paper = Color(red: 249/255, green: 248/255, blue: 242/255)
    static let ink = Color(red: 0.13, green: 0.15, blue: 0.16)
    static let blue = Color(red: 0.28, green: 0.39, blue: 0.44)
    static let red = Color(red: 0.71, green: 0.19, blue: 0.15)

    var body: some View {
        GeometryReader { box in
            let size = box.size
            let wide = size.width > size.height * 1.4
            let compact = widget && size.height < 220
            let unit = min(size.width / 300, size.height / 400)
            ZStack {
                Self.paper
                PaperGrain(seed: reading.info.dayOfYear, strength: 0.5)
                if wide {
                    let scale = min(size.width / 340, size.height / 158)
                    HStack(spacing: 14 * scale) {
                        illustration.frame(width: 120 * scale, height: 120 * scale)
                        VStack(spacing: 5 * scale) {
                            date(size: 38 * scale, label: 10 * scale)
                            phase(size: 11 * scale)
                            footer(size: 10 * scale)
                        }.frame(maxWidth: .infinity)
                    }.padding(.horizontal, 15 * scale)
                } else if compact {
                    let scale = min(size.width, size.height) / 158
                    VStack(spacing: 3 * scale) {
                        Text(verbatim: reading.info.weekdayEN.uppercased() + "  ·  " + month + " " + String(reading.info.day))
                            .font(.system(size: 13 * scale, weight: .semibold))
                        illustration.frame(width: 86 * scale, height: 86 * scale)
                        phase(size: 10 * scale)
                        Text(verbatim: reading.milestone?.name ?? reading.constellation.rawValue)
                            .font(.system(size: 10 * scale)).foregroundStyle(Self.blue)
                    }
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Text(verbatim: "月")
                            Spacer()
                            Text(verbatim: String(reading.info.year)).monospacedDigit()
                        }
                        .font(.system(size: 12 * unit, weight: .medium))
                        date(size: 57 * unit, label: 11 * unit)
                        Spacer(minLength: 3 * unit)
                        illustration.frame(width: 180 * unit, height: 164 * unit)
                        phase(size: 12 * unit).padding(.top, 5 * unit)
                        Spacer(minLength: 6 * unit)
                        footer(size: 11 * unit)
                    }
                    .padding(.horizontal, 22 * unit)
                    .padding(.top, (widget ? 15 : 32) * unit)
                    .padding(.bottom, 16 * unit)
                }
            }.foregroundStyle(Self.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reading.summary)
    }

    private var month: String { monthNamesEN[reading.info.month].uppercased() }

    private func date(size: CGFloat, label: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(verbatim: month).tracking(label * 0.13).font(.system(size: label))
            Text(verbatim: String(reading.info.day))
                .font(.custom("HelveticaNeue-Bold", fixedSize: size))
                .fixedSize()
                .foregroundStyle(reading.info.isSunday || reading.info.page.holiday != nil ? Self.red : Self.ink)
                .dayNumberTarget()
            Text(verbatim: weekdayNamesEN[reading.info.weekday].uppercased())
                .font(.system(size: label)).tracking(label * 0.06)
        }
    }

    private func phase(size: CGFloat) -> some View {
        Text(verbatim: [reading.phase, reading.illumination].compactMap { $0 }.joined(separator: "  ·  "))
            .font(.system(size: size, weight: .medium)).foregroundStyle(Self.blue)
    }

    private func footer(size: CGFloat) -> some View {
        VStack(spacing: size * 0.3) {
            Text(verbatim: reading.caption.uppercased())
                .font(.system(size: size * 0.88, weight: .semibold)).tracking(size * 0.10)
            Text(verbatim: reading.note)
                .font(.system(size: size)).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var illustration: some View {
        GeometryReader { box in
            let d = min(box.size.width, box.size.height)
            ZStack {
                if let sky = reading.sky {
                    let texture = Image("MoonPrint", bundle: Bundle(for: MoonArtwork.self))
                        .resizable().aspectRatio(1, contentMode: .fit).clipShape(Circle())
                    ZStack {
                        texture.opacity(0.11)
                        texture.mask {
                            IlluminatedLimb(fraction: sky.moonIllumination, waxing: sky.moonIsWaxing)
                        }
                    }.frame(width: d, height: d)
                }
                if let milestone = reading.milestone {
                    MissionDrawing(mission: milestone.drawing)
                        .padding(d * 0.045)
                        .background(Circle().fill(Self.paper))
                        .frame(width: d * 0.43, height: d * 0.43)
                        .offset(x: d * 0.34, y: d * 0.29)
                } else if reading.darkSky {
                    ConstellationDrawing(constellation: reading.constellation)
                        .frame(width: d * 0.70, height: d * 0.70)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.accessibilityHidden(true)
    }
}

private final class MoonArtwork {}
