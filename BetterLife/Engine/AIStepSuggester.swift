import Foundation

/// "AI" step suggestions (MVP): deterministic, local, rule-based.
///
/// Design goals:
/// - Always relevant to the user's habit text (avoid generic unrelated templates)
/// - 30s-ish micro steps, single action, concrete
/// - If unsure, return a small set that *includes the habit text* so user can edit
enum AIStepSuggester {

    static func suggestMicroSteps(habitName raw: String) -> [String] {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return [] }

        let n = normalize(name)

        // Sleep / bedtime
        if containsAny(n, ["睡", "眠", "上床", "早睡", "熄燈", "關燈", "入睡"]) {
            return dedupe([
                "把手機放遠離床邊充電",
                "把燈光調暗（或關大燈）",
                "設定一個『準備睡』提醒",
                "上床，蓋好被，閉眼10秒",
                "把明天要用的東西放好（衣服/包/鑰匙）",
                "把房間收走1件物品，讓自己收工",
                "寫下一句：明天最重要的一件事"
            ])
        }

        // Reading
        if containsAny(n, ["讀", "閱讀", "看書", "小說", "書"]) {
            // Diversity rules (implicit):
            // - Only ONE "time/quantity" step is needed; the rest should be different angles.
            return dedupe([
                // Start / friction remover
                "把書放到手邊",
                "打開書到下一頁",
                "坐好，讓眼睛對準書頁10秒",
                "先讀第一句就好",

                // Time/quantity (keep just one default)
                "讀1段（或1頁）",

                // Reflection / meaning
                "用一句話回想：剛剛在講什麼？",
                "寫下一句：我今天讀到…",
                "把最喜歡的一句抄下來",

                // Planning / continuity
                "把明天要讀的頁碼寫在書籤上",
                "把這本書加入『想讀/在讀』清單",
                "選好下一次要讀的書，先放出來",

                // Mark / capture
                "在書籤貼一個小記號",
                "在書頁夾一張便條（只寫3個字也可以）"
            ])
        }

        // Exercise / movement
        if containsAny(n, ["運動", "健身", "瑜伽", "跑", "慢跑", "拉伸", "伸展", "深蹲", "伏地挺身", "走路", "散步"]) {
            return dedupe([
                "換上運動鞋/運動服",
                "站起來伸展30秒",
                "做5次深蹲",
                "做5次肩頸放鬆",
                "走到門口（或樓下）就算完成",
                "打開運動App/影片，按下播放",
                "喝兩口水，準備開始"
            ])
        }

        // Writing / journaling
        if containsAny(n, ["寫", "日記", "筆記", "寫作", "寫字", "反思"]) {
            return dedupe([
                "打開筆記本/備忘錄",
                "寫下一句今天的心情",
                "寫3個字也可以",
                "把標題寫好：『今天』",
                "寫一件今天做得不錯的小事",
                "寫下明天想做的一件小事",
                "把筆放到桌上，準備開始"
            ])
        }

        // Language learning
        if containsAny(n, ["英文", "日文", "韓文", "法文", "德文", "學習", "背單字", "單字"]) {
            return dedupe([
                "打開學習App",
                "複習3個單字",
                "聽30秒發音",
                "跟讀一句",
                "把今天要學的清單打開",
                "把手機調成勿擾5分鐘",
                "完成1個小測驗題"
            ])
        }

        // Hydration
        if containsAny(n, ["喝水", "飲水", "水"]) {
            return dedupe([
                "倒一杯水放手邊",
                "喝三口水",
                "把水瓶裝滿",
                "在桌上放好水瓶",
                "把水放到你最常看到的地方",
                "設定每2小時提醒喝水"
            ])
        }

        // Default: stay relevant by embedding the habit name.
        // We avoid empty/generic advice; these are meant to be edited.
        return dedupe([
            "把『\(name)』需要的東西放到眼前",
            "把『\(name)』的第一個動作寫成一句話",
            "只做30秒：『\(name)』的最小版本",
            "打開/準備開始『\(name)』",
            "把環境整理到可以開始『\(name)』的程度"
        ])
    }

    // MARK: - Helpers

    private static func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "：", with: ":")
    }

    private static func containsAny(_ s: String, _ keywords: [String]) -> Bool {
        for k in keywords {
            if s.contains(k.lowercased()) { return true }
        }
        return false
    }

    private static func dedupe(_ items: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for i in items {
            if seen.contains(i) { continue }
            seen.insert(i)
            out.append(i)
        }
        return out
    }
}
