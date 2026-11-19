import SwiftUI
import TungShingDailyAlmanac

struct LichVietReading {
    let info: DayInfo
    let lunar: VietnameseLunarDate?
    static let branches = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
    private static let stems = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    private static let animals = ["Rat", "Water Buffalo", "Tiger", "Cat", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
    private static let months = ["Giêng", "Hai", "Ba", "Tư", "Năm", "Sáu", "Bảy", "Tám", "Chín", "Mười", "Mười một", "Chạp"]

    init(_ page: PrintedDay) {
        info = DayInfo(page: page)
        lunar = VietnameseLunarDate(on: page.date)
    }

    var weekday: String { ["Chủ nhật", "Thứ hai", "Thứ ba", "Thứ tư", "Thứ năm", "Thứ sáu", "Thứ bảy"][info.weekday - 1] }
    private func cycle(_ index: Int) -> String { Self.stems[index % 10] + " " + Self.branches[index % 12] }
    var dayName: String { cycle(info.report.dayPillar.index) }
    var dayAnimal: String { Self.animals[info.report.dayPillar.branchIndex] }
    var dayAnimalAsset: String { "LichViet" + dayAnimal.replacingOccurrences(of: " ", with: "") }
    var yearName: String { lunar.map { cycle(($0.year - 4) % 60) } ?? "—" }
    var animal: String { lunar.map { Self.animals[($0.year - 4) % 12] } ?? "—" }
    var monthName: String { lunar.map { "Tháng " + Self.months[$0.month - 1] + ($0.isLeapMonth ? " nhuận" : "") } ?? "—" }
    var lunarLine: String { lunar.map { "Âm lịch · " + String($0.day) + " · " + monthName } ?? "Âm lịch —" }
    var festival: (name: String, english: String)? {
        guard let lunar, !lunar.isLeapMonth else { return nil }
        switch (lunar.month, lunar.day) {
        case (1, 1): return ("Tết Nguyên Đán", "Lunar New Year")
        case (1, 2): return ("Mùng Hai Tết", "Second day of Tết")
        case (1, 3): return ("Mùng Ba Tết", "Third day of Tết")
        case (1, 15): return ("Tết Nguyên Tiêu", "First full moon of the year")
        case (3, 10): return ("Giỗ Tổ Hùng Vương", "Hùng Kings’ commemoration")
        case (5, 5): return ("Tết Đoan Ngọ", "Double Fifth Festival")
        case (8, 15): return ("Tết Trung Thu", "Mid-Autumn Festival")
        case (12, 23): return ("Tết ông Công ông Táo", "Kitchen Gods’ Day")
        default: return nil
        }
    }

    var ink: Color { info.isSunday || festival != nil ? LichVietFace.red : LichVietFace.green }

    // The six auspicious double hours advance two branches per day and repeat after six days.
    var hours: [Int] {
        let offset = 2 * (info.report.dayPillar.branchIndex % 6)
        return [0, 1, 3, 6, 8, 9].map { ($0 + offset) % 12 }.sorted()
    }
    var summary: String {
        ([info.page.date.label, weekday, lunarLine, "Năm " + yearName, "Year of the " + animal,
          "Ngày " + dayName + " (" + dayAnimal + ")", festival?.name, festival?.english, "Giờ hoàng đạo: " + hours.map { Self.branches[$0] }.joined(separator: ", ")] as [String?])
            .compactMap { $0 }.joined(separator: ". ")
    }
}

struct LichVietBlossom: View {
    var body: some View {
        Canvas { ctx, size in
            let unit = min(size.width, size.height)
            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.scaleBy(x: unit, y: unit)
            for _ in 0..<5 {
                ctx.fill(Path(ellipseIn: CGRect(x: -0.15, y: -0.45, width: 0.30, height: 0.36)), with: .foreground)
                ctx.rotate(by: .degrees(72))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: -0.08, y: -0.08, width: 0.16, height: 0.16)), with: .foreground)
        }.accessibilityHidden(true)
    }
}

struct LichVietBinding: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle().frame(height: 0.7)
            ForEach(0..<3) { index in
                LichVietBlossom().frame(width: index == 1 ? 12 : 7)
            }
            Rectangle().frame(height: 0.7)
        }
        .padding(.horizontal, 12)
        .foregroundStyle(Color(red: 1, green: 0.82, blue: 0.48))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LichVietFace.red)
    }
}

struct LichVietFace: View {
    let reading: LichVietReading
    var widget = false
    static let paper = Color(red: 1, green: 0.995, blue: 0.974)
    static let green = Color(red: 0.035, green: 0.42, blue: 0.28)
    static let red = Color(red: 0.72, green: 0.13, blue: 0.105)
    private var info: DayInfo { reading.info }
    private func type(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Georgia-Bold" : "Georgia", fixedSize: size)
    }
    private func day(_ size: CGFloat) -> some View {
        Text(verbatim: String(info.day))
            .font(.custom("BodoniSvtyTwoITCTT-Bold", fixedSize: size))
            .kerning(-size * 0.035).fixedSize().padding(.horizontal, size * 0.025).dayNumberTarget()
    }
    private func rule(_ u: CGFloat) -> some View { Rectangle().frame(height: 0.75 * u) }

    var body: some View {
        GeometryReader { box in
            let w = box.size.width, h = box.size.height
            Group {
                if widget && h < 230 {
                    compact(wide: w > h * 1.4)
                } else {
                    let u = min(w / 300, h / (widget ? 370 : 400))
                    VStack(spacing: 0) {
                        HStack {
                            Text(verbatim: String(info.year))
                            Spacer()
                            Text(verbatim: monthNamesEN[info.month].capitalized)
                        }.font(type(18 * u, bold: true)).padding(.horizontal, 6 * u)
                        Spacer(minLength: 0)
                        day(147 * u).frame(height: 116 * u)
                        Text(verbatim: weekdayNamesEN[info.weekday].capitalized)
                            .font(type(25 * u, bold: true))
                        Spacer(minLength: 0)
                        rule(u)
                        HStack(spacing: 0) {
                            cell("Năm " + reading.yearName, "Year of the " + reading.animal, u)
                                .padding(.horizontal, 3 * u)
                            Rectangle().frame(width: 0.7 * u)
                            Text(verbatim: reading.lunar.map { String($0.day) } ?? "—")
                                .font(type(37 * u, bold: true)).lineLimit(1).minimumScaleFactor(0.78)
                                .padding(.horizontal, 2 * u).frame(width: 50 * u)
                            Rectangle().frame(width: 0.7 * u)
                            animalStamp(34 * u).frame(width: 40 * u)
                            Rectangle().frame(width: 0.7 * u)
                            cell(reading.monthName, "Âm lịch", u)
                        }.frame(height: 51 * u)
                        rule(u)
                        VStack(spacing: 4 * u) {
                            Text(verbatim: reading.festival?.name ?? ("Ngày " + reading.dayName))
                                .font(type(18 * u, bold: true))
                            Text(verbatim: reading.festival.map { $0.english + "  ·  " + reading.dayName } ?? reading.weekday)
                                .font(type(12 * u))
                        }.frame(maxWidth: .infinity).frame(height: 55 * u)
                        rule(u)
                        Text("GIỜ HOÀNG ĐẠO").tracking(1.8 * u).font(type(9 * u, bold: true)).padding(.vertical, 4 * u)
                        rule(u)
                        HStack(spacing: 0) {
                            ForEach(reading.hours, id: \.self) { index in
                                if index != reading.hours.first { Rectangle().frame(width: 0.6 * u) }
                                cell(LichVietReading.branches[index], String(format: "%02d–%02d", (index * 2 + 23) % 24, index * 2 + 1), u)
                            }
                        }.frame(height: 35 * u)
                    }
                    .overlay(Rectangle().strokeBorder(lineWidth: 1.1 * u))
                    .padding(3 * u)
                    .overlay(Rectangle().strokeBorder(lineWidth: 0.6 * u))
                    .padding(.horizontal, 12 * u).padding(.bottom, 9 * u)
                    .padding(.top, (widget ? 8 : 30) * u)
                    .frame(maxWidth: min(w, h * 1.1))
                }
            }
            .frame(width: w, height: h)
            .foregroundStyle(reading.ink).background(Self.paper)
        }.accessibilityElement(children: .ignore).accessibilityLabel(reading.summary)
    }

    private final class ArtworkBundle {}
    private func animalStamp(_ size: CGFloat) -> some View {
        Image(reading.dayAnimalAsset, bundle: Bundle(for: ArtworkBundle.self))
            .renderingMode(.template).resizable().scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private func cell(_ top: String, _ bottom: String, _ u: CGFloat) -> some View {
        VStack(spacing: 3 * u) {
            Text(verbatim: top).font(type(12 * u, bold: true))
            Text(verbatim: bottom).font(type(10 * u))
        }.lineLimit(1).minimumScaleFactor(0.78).frame(maxWidth: .infinity)
    }

    private func compact(wide: Bool) -> some View {
        let layout = wide ? AnyLayout(HStackLayout(spacing: 14)) : AnyLayout(VStackLayout(spacing: 3))
        return layout {
            VStack(spacing: 0) {
                Text(verbatim: monthNamesEN[info.month].capitalized + " " + String(info.year)).font(type(12, bold: true))
                day(wide ? 77 : 53).frame(height: wide ? 74 : 51)
                Text(verbatim: reading.weekday).font(type(13, bold: true))
            }
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    animalStamp(wide ? 26 : 19)
                    Text(verbatim: reading.lunarLine)
                }
                Text(verbatim: reading.festival?.name ?? ("Năm " + reading.yearName))
                    .fontWeight(.bold)
            }.font(type(wide ? 13 : 11)).multilineTextAlignment(.center)
        }.padding(6).frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(5)
    }
}
