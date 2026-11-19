import Foundation
import TungShingCore

/// Traditional Japanese names in spring-first order. Each kō begins on the
/// Japanese civil day containing its 5° apparent solar-longitude crossing.
public struct JapaneseSeason: Sendable {
    public let number: Int
    public let term: String
    public let termEnglish: String
    public let microseason: String
    public let microseasonEnglish: String

    public init?(on date: GregorianDate) {
        guard DailyAlmanacReader.firstDate <= date, date <= DailyAlmanacReader.lastDate,
              let starts = Self.starts else { return nil }
        var low = 0, high = starts.count
        while low < high {
            let mid = low + (high - low) / 2
            if starts[mid] <= date.dayID.value { low = mid + 1 } else { high = mid }
        }
        guard low > 0 else { return nil }
        let index = (low - 1) % 72
        number = index + 1
        let entry = Self.catalog[index / 3]
        (term, termEnglish) = entry.term
        (microseason, microseasonEnglish) = entry.seasons[index % 3]
    }

    private static let starts: [Int64]? = DailyAlmanacResources.data("japanese-microseason-starts").flatMap {
        try? JSONDecoder().decode([Int64].self, from: $0)
    }

    private static let catalog: [(term: (String, String), seasons: [(String, String)])] = [
        (("立春", "Spring begins"), [
            ("東風解凍", "An east wind loosens the ice"),
            ("黄鶯睍睆", "Bush warblers find their voice"),
            ("魚上氷", "Fish rise through broken ice")]),
        (("雨水", "Rain water"), [
            ("土脉潤起", "The soil drinks the first rains"),
            ("霞始靆", "A veil of haze settles"),
            ("草木萌動", "Grass and trees send out shoots")]),
        (("啓蟄", "Insects awaken"), [
            ("蟄虫啓戸", "Insects stir beneath the soil"),
            ("桃始笑", "Peach blossoms open"),
            ("菜虫化蝶", "Butterflies emerge among the greens")]),
        (("春分", "Spring equinox"), [
            ("雀始巣", "Sparrows gather nesting straw"),
            ("桜始開", "The first cherry buds open"),
            ("雷乃発声", "Spring thunder sounds")]),
        (("清明", "Clear and bright"), [
            ("玄鳥至", "Swallows return to the eaves"),
            ("鴻雁北", "Wild geese turn north"),
            ("虹始見", "The first rainbow appears")]),
        (("穀雨", "Grain rain"), [
            ("葭始生", "Reeds send up green spears"),
            ("霜止出苗", "Frost gives way to seedlings"),
            ("牡丹華", "Peonies unfold")]),
        (("立夏", "Summer begins"), [
            ("蛙始鳴", "Frogs begin their chorus"),
            ("蚯蚓出", "Earthworms surface"),
            ("竹笋生", "Bamboo shoots break ground")]),
        (("小満", "Grain fills"), [
            ("蚕起食桑", "Silkworms feed on mulberry leaves"),
            ("紅花栄", "Safflowers come into bloom"),
            ("麦秋至", "Barley ripens for harvest")]),
        (("芒種", "Grain in ear"), [
            ("蟷螂生", "Young mantises hatch"),
            ("腐草為蛍", "Fireflies rise from the damp grass"),
            ("梅子黄", "Plums turn yellow on the branch")]),
        (("夏至", "Summer solstice"), [
            ("乃東枯", "Self-heal flower heads dry"),
            ("菖蒲華", "Irises open"),
            ("半夏生", "Crow-dipper sprouts")]),
        (("小暑", "Lesser heat"), [
            ("温風至", "The wind turns warm"),
            ("蓮始開", "Lotus flowers open"),
            ("鷹乃学習", "Young hawks try their wings")]),
        (("大暑", "Greater heat"), [
            ("桐始結花", "Paulownia sets its buds"),
            ("土潤溽暑", "The earth steams in the heat"),
            ("大雨時行", "Heavy showers sweep through")]),
        (("立秋", "Autumn begins"), [
            ("涼風至", "The breeze carries a little coolness"),
            ("寒蝉鳴", "Evening cicadas call"),
            ("蒙霧升降", "Deep mists rise and settle")]),
        (("処暑", "Heat recedes"), [
            ("綿柎開", "Cotton bolls split open"),
            ("天地始粛", "The heat eases from earth and sky"),
            ("禾乃登", "Heads of rice grow heavy")]),
        (("白露", "White dew"), [
            ("草露白", "Dew whitens the grass"),
            ("鶺鴒鳴", "Wagtails call"),
            ("玄鳥去", "Swallows take their leave")]),
        (("秋分", "Autumn equinox"), [
            ("雷乃収声", "Thunder falls silent"),
            ("蟄虫坏戸", "Insects seal their burrows"),
            ("水始涸", "Water drains from the fields")]),
        (("寒露", "Cold dew"), [
            ("鴻雁来", "Wild geese arrive"),
            ("菊花開", "Chrysanthemums bloom"),
            ("蟋蟀在戸", "Crickets sing at the door")]),
        (("霜降", "Frost descends"), [
            ("霜始降", "The first frost settles"),
            ("霎時施", "Brief showers pass"),
            ("楓蔦黄", "Maple and ivy turn colour")]),
        (("立冬", "Winter begins"), [
            ("山茶始開", "Sasanqua camellias open"),
            ("地始凍", "The ground begins to freeze"),
            ("金盞香", "Narcissus flowers scent the air")]),
        (("小雪", "Lesser snow"), [
            ("虹蔵不見", "Rainbows fade from view"),
            ("朔風払葉", "The north wind sweeps away leaves"),
            ("橘始黄", "Tachibana fruit turns gold")]),
        (("大雪", "Greater snow"), [
            ("閉塞成冬", "Winter closes in"),
            ("熊蟄穴", "Bears settle into their dens"),
            ("鱖魚群", "Salmon gather in the rivers")]),
        (("冬至", "Winter solstice"), [
            ("乃東生", "Self-heal sends up shoots"),
            ("麋角解", "Deer shed their antlers"),
            ("雪下出麦", "Barley pushes through the snow")]),
        (("小寒", "Lesser cold"), [
            ("芹乃栄", "Water dropwort flourishes"),
            ("水泉動", "Springs stir beneath the ice"),
            ("雉始雊", "Pheasants begin to call")]),
        (("大寒", "Greater cold"), [
            ("款冬華", "Butterbur buds appear"),
            ("水沢腹堅", "Pond ice thickens"),
            ("鶏始乳", "Hens begin laying eggs")]),
    ]
}
