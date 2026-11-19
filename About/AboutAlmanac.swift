import SwiftUI

struct AboutAlmanac: View {
    private let paper = Color(red: 0.985, green: 0.977, blue: 0.945)
    private let ink = Color(red: 0.09, green: 0.23, blue: 0.18)
    private let redInk = Color(red: 0.60, green: 0.16, blue: 0.15)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Link(destination: URL(string: "https://wadscorp.com/")!) {
                    HStack(spacing: 10) {
                        Image("Wadscorp")
                            .renderingMode(.original).resizable().scaledToFit()
                            .frame(width: 42, height: 36).accessibilityHidden(true)
                        Text("Wadscorp")
                            .font(.system(.headline, design: .serif).weight(.semibold))
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Wadscorp website")
                VStack(alignment: .leading, spacing: 5) {
                    Text(AppIdentity.name)
                        .font(.system(.largeTitle, design: .serif).weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Text(AppIdentity.subtitle).font(.body)
                    if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                       let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                        Text("Version \(version) (\(build))").font(.caption.monospacedDigit())
                    }
                }
                Rectangle().fill(ink).frame(height: 2).accessibilityHidden(true)
                credit("Himekuri 日めくり") {
                    Text("Paper Almanac grew out of Pluk’s Himekuri for Mac. Its tear-off pad and the Shōwa, Koyomi, Tong Sheng and Huangli designs inspired this edition. Paper Almanac uses its own Metal simulation for lifting and tearing the sheet.")
                    Text("[Original Himekuri project](https://github.com/pluk-inc/himekuri)")
                    license("MIT License · © 2026 Pluk", resource: "Himekuri-LICENSE")
                }
                Divider()
                credit("Print references") {
                    Text("The Tung Shing face draws on the [YutLik calendar](https://ricefolk.com/back-on-the-boat-jason-soy-sally-fung-of-yutlik-calendar/) by Jason Soy and Sally Fung of Back On The Boat.")
                    Text("Celestial Almanac’s translucent numerals and astronomical diagrams draw on [NOTON’s Himekuri calendar](https://noton.info/product/nx015/), designed by Carsten Nicolai and nibo.")
                }
                credit("Fuji") {
                    Text("Fuji’s cardboard mount and spare layout draw on [MUJI’s 2027 tear-off calendar](https://www.muji.us/products/2027-tear-off-calendar-ne2bua6a). Its Japanese public holidays are adapted from Japan’s Cabinet Office.")
                    Text(verbatim: FujiReading.sourceNotes)
                        .font(.footnote)
                    Text("[Cabinet Office holiday tables](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html)")
                }
                credit("Daily readings") {
                    Text("The Wadscorp Tung Shing engine supplies the daily almanac. Celestial Almanac’s historical launch entries use [Jonathan McDowell’s General Catalog of Artificial Space Objects](https://planet4589.org/space/gcat/) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).")
                }
                credit("Chinese proverbs") {
                    Text("Selected from English Wiktionary contributors via [Kaikki](https://kaikki.org/dictionary/Chinese/pos-proverb/index.html). Some English readings are abridged or reworded. The collection is shared under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).")
                }
                credit("Type & sound") {
                    Text("Taviraj Medium, designed by Cadson Demak, gives the Tung Shing date its distinctive numerals.")
                    license("SIL Open Font License 1.1", resource: "Taviraj-LICENSE")
                    Text("Paper tearing sounds are synthesized by the app.")
                }
            }
            .frame(maxWidth: 530, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(paper)
        .foregroundStyle(ink)
        .tint(redInk)
        .environment(\.colorScheme, .light)
        .accessibilityIdentifier("about-almanac")
    }

    private func credit(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
            content()
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func license(_ title: String, resource: String) -> some View {
        if let file = Bundle.main.url(forResource: resource, withExtension: "txt"),
           let notice = try? String(contentsOf: file, encoding: .utf8) {
            DisclosureGroup(title) {
                Text(verbatim: notice)
                    .font(.footnote).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
        }
    }
}
