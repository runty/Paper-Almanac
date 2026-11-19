// English glosses for the 81 activity tokens of the pinned cnlunar profile. Glosses marked (reviewed) follow the
// research activity appendix (TUNG_SHING_OFFICER_ACTIVITIES.md, "Practical activity ID glossary"). Glosses marked
// (unreviewed) are plain readings written for tokens the appendix does not gloss; the owner should review them.

enum ActivityGlosses {
    static let table: [String: String] = [
        "上册": "Submit registers",            // (unreviewed) 上册進表章
        "上官": "Take up office",              // (reviewed) assume_office
        "上表章": "Submit memorials",          // (unreviewed)
        "临政": "Administer public affairs",   // (reviewed) administer_people
        "举正直": "Promote the upright",       // (unreviewed)
        "乘船渡水": "Travel by boat",          // (unreviewed)
        "伐木": "Fell trees",                  // (reviewed) fell_trees
        "修仓库": "Repair storehouses",        // (reviewed) repair_warehouse
        "修宫室": "Repair buildings",          // (reviewed) repair_building
        "修置产室": "Prepare a birth room",    // (reviewed) prepare_birth_room
        "修造": "Build or renovate",           // (reviewed) construction_earthwork
        "修饰垣墙": "Finish walls",            // (reviewed) finish_wall
        "入学": "Begin studies",               // (unreviewed)
        "入宅": "Move into a home",            // (unreviewed)
        "冠带": "Coming-of-age rites",         // (reviewed) coming_of_age
        "出师": "Launch a campaign",           // (reviewed) military_campaign
        "出行": "Travel",                      // (reviewed) shares 行幸遣使 rules
        "剃头": "Cut hair",                    // (reviewed) groom_cut_hair
        "取鱼": "Fish",                        // (reviewed) fish
        "启攒": "Open a temporary burial",     // (reviewed) exhumation
        "塞穴": "Block openings",              // (reviewed) block_opening
        "嫁娶": "Wedding ceremony",            // (reviewed) marriage_ceremony
        "安床": "Set up a bed",                // (reviewed) install_bed
        "安抚边境": "Settle the frontier",     // (reviewed) pacify_frontier
        "安碓硙": "Install a mill",            // (reviewed) install_mill
        "安葬": "Burial",                      // (reviewed) burial
        "宣政事": "Proclaim policy",           // (unreviewed)
        "宴会": "Hold a banquet",              // (unreviewed)
        "布政事": "Issue policy",              // (unreviewed)
        "平治道涂": "Level roads",             // (reviewed) level_road
        "庆赐": "Celebrate and bestow gifts",  // (unreviewed)
        "开仓": "Open storehouses",            // (reviewed) open_warehouse
        "开市": "Open for business",           // (reviewed) open_market
        "开张": "Open a shop",                 // (unreviewed)
        "开渠": "Open channels",               // (reviewed) dig_channel
        "恤孤茕": "Aid the orphaned and alone", // (unreviewed)
        "扫舍宇": "Clean the house",           // (reviewed) clean_house
        "招贤": "Recruit the worthy",          // (unreviewed)
        "捕捉": "Capture",                     // (reviewed) capture
        "搬移": "Move house",                  // (reviewed) move_residence
        "整容": "Groom",                       // (reviewed) groom_cut_hair
        "整手足甲": "Trim nails",              // (reviewed) trim_nails
        "施恩": "Grant favours",               // (unreviewed)
        "栽种": "Plant",                       // (reviewed) plant
        "求医疗病": "Seek treatment",          // (reviewed) seek_treatment
        "求嗣": "Pray for descendants",        // (reviewed) pray_descendant
        "沐浴": "Ritual bathing",              // (reviewed) ritual_bathe
        "牧养": "Tend livestock",              // (reviewed) tend_livestock
        "畋猎": "Hunt",                        // (reviewed) hunt
        "疗目": "Treat the eyes",              // (unreviewed) 求醫療目 variant
        "破土": "Break ground for burial",     // (reviewed) burial_earthwork
        "破屋坏垣": "Demolish ruined buildings", // (reviewed) demolish_ruined_building
        "祈福": "Pray for blessings",          // (reviewed) pray_blessing
        "祭祀": "Make offerings",              // (reviewed) ritual_offering
        "穿井": "Dig a well",                  // (reviewed) dig_well
        "立券": "Sign a contract",             // (reviewed) execute_contract
        "立券交易": "Sign contracts and trade", // (reviewed) execute_contract + trade
        "竖柱上梁": "Raise columns and beams", // (reviewed) erect_columns_beam
        "筑堤防": "Build embankments",         // (reviewed) construct_embankment
        "纳畜": "Acquire livestock",           // (reviewed) acquire_livestock
        "纳财": "Receive wealth",              // (reviewed) receive_wealth
        "纳采": "Betrothal gifts",             // (reviewed) betrothal
        "经络": "Set up the loom",             // (reviewed) set_up_weaving
        "结婚姻": "Arrange a marriage",        // (reviewed) arrange_marriage
        "缮城郭": "Repair city walls",         // (reviewed) repair_city_wall
        "苫盖": "Thatch a roof",               // (unreviewed)
        "营建": "Construct buildings",         // (reviewed) construct_building
        "补垣": "Repair walls",                // (reviewed) repair_wall
        "裁制": "Cut and make clothes",        // (reviewed) cut_make_clothing
        "覃恩": "Extend grace",                // (unreviewed) 覃恩肆赦
        "解除": "Ritual release",              // (reviewed) ritual_release
        "诉讼": "Litigation",                  // (unreviewed)
        "赴任": "Take up a post",              // (unreviewed) from 上官赴任
        "进人口": "Add household members",     // (reviewed) add_household_member
        "远回": "Return from afar",            // (unreviewed)
        "选将": "Appoint commanders",          // (reviewed) appoint_train_troops
        "酝酿": "Brew",                        // (reviewed) brew
        "针刺": "Acupuncture",                 // (reviewed) acupuncture
        "雪冤": "Clear a wrong",               // (unreviewed)
        "颁诏": "Issue a decree",              // (unreviewed)
        "鼓铸": "Cast metal",                  // (unreviewed)
    ]

    /// Tokens whose gloss is a plain reading awaiting the owner's review.
    static let unreviewed: Set<String> = [
        "上册", "上表章", "举正直", "乘船渡水", "入学", "入宅", "宣政事", "宴会", "布政事", "庆赐", "开张", "恤孤茕", "招贤",
        "施恩", "疗目", "苫盖", "覃恩", "诉讼", "赴任", "远回", "雪冤", "颁诏", "鼓铸",
    ]

    /// The evaluator's list sentinels (lunar.py 諸事皆忌 / 諸事不忌): a statement in the list's place, not an activity of
    /// the 81-token vocabulary, so they are glossed apart from the table. 諸事不宜 stands in an empty 宜 list ("nothing
    /// is suitable"); a day whose grade avoids everything carries it in both lists, where under 忌 its sense is every
    /// undertaking, so that column glosses it "Everything". 諸事不忌 stands in an empty 忌 list.
    static let sentinels: [String: String] = [
        "诸事不宜": "Nothing is suitable",
        "诸事不忌": "Nothing to avoid",
    ]
    static let avoidListSentinel = "诸事不宜"
    static let avoidListSentinelEnglish = "Everything"

    static func english(_ token: String) -> String? { table[token] ?? sentinels[token] }

    /// The gloss as a list prints it: under 忌 the 宜 sentinel reads "Everything".
    static func english(_ token: String, underAvoid: Bool) -> String? {
        underAvoid && token == avoidListSentinel ? avoidListSentinelEnglish : english(token)
    }
}
