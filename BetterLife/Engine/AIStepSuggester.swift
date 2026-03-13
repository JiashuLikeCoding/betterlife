import Foundation

/// "AI" step suggestions (MVP): deterministic, local, rule-based.
///
/// Design goals:
/// - Always relevant to the user's habit text (avoid generic unrelated templates)
/// - 30s-ish micro steps, single action, concrete
/// - If unsure, return a small set that *includes the habit text* so user can edit
enum AIStepSuggester {

    static func suggestMicroSteps(habitName raw: String, coachProfile: CoachProfile? = nil) -> [String] {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return [] }

        let n = normalize(name)

        if let profile = coachProfile {
            let fromProfile = suggestFromProfile(habitName: name, profile: profile)
            if !fromProfile.isEmpty {
                return fromProfile
            }
        }

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

    // MARK: - Coach profile

    private static func suggestFromProfile(habitName: String, profile: CoachProfile) -> [String] {
        let answers = profile.answers
        let other = profile.otherText

        func pick(_ key: String) -> [String] {
            (answers[key] ?? []).filter { !$0.isEmpty }
        }
        func otherText(_ key: String) -> String {
            (other[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        switch profile.kind {
        case .exercise:
            let types = pick("exercise.type") + (otherText("exercise.type_other").isEmpty ? [] : [otherText("exercise.type_other")])
            let barrier = (pick("exercise.barrier").first ?? otherText("exercise.barrier_other"))
            let dose = (pick("exercise.dose").first ?? otherText("exercise.dose_other"))

            // Choose a single concrete direction from types.
            let t = types.first ?? "運動"
            return dedupe([
                // start/setup
                "換上運動鞋/運動服",
                barrier.contains("不想出門") ? "走到門口就算完成" : "站起來伸展30秒",

                // do (varies by type)
                t.contains("瑜伽") || t.contains("伸展") ? "做一個肩頸放鬆動作30秒" : "做5次深蹲",

                // dose (only one)
                dose.isEmpty ? "做1分鐘最小版本" : "做\(dose)最小版本",

                // reflect/continue
                "用一句話感受：身體最緊的是哪裡？",
                "把運動鞋放在門口（讓明天更好開始）"
            ])

        case .sleep:
            let bedtime = (pick("sleep.bedtime").first ?? otherText("sleep.bedtime_other"))
            let barrier = (pick("sleep.barrier").first ?? otherText("sleep.barrier_other"))
            let ritual = (pick("sleep.ritual").first ?? otherText("sleep.ritual_other"))

            var steps: [String] = []
            steps.append(ritual.isEmpty ? "把燈光調暗（或關大燈）" : ritual)
            if barrier.contains("手機") {
                steps.append("把手機放遠離床邊充電")
            }
            if !bedtime.isEmpty {
                steps.append("設定\(bedtime)前的『準備睡』提醒")
            } else {
                steps.append("設定一個『準備睡』提醒")
            }
            steps.append("上床，蓋好被，閉眼10秒")
            steps.append("把明天要用的東西放好（衣服/包/鑰匙）")
            steps.append("寫下一句：明天最重要的一件事")
            return dedupe(steps)

        case .wake:
            let wakeTime = (pick("wake.time").first ?? otherText("wake.time_other"))
            let barrier = (pick("wake.barrier").first ?? otherText("wake.barrier_other"))
            let first = (pick("wake.first").first ?? otherText("wake.first_other"))

            var steps: [String] = []
            if !wakeTime.isEmpty { steps.append("設定\(wakeTime)起床（先回來就好）") }
            steps.append(first.isEmpty ? "坐起身10秒" : first)
            steps.append("下床站起來（只要站起來就好）")
            if barrier.contains("手機") {
                steps.append("把手機放遠一點（起床後再看）")
            }
            steps.append("打開窗呼吸一口氣")
            steps.append("喝三口水")
            return dedupe(steps)

        case .reading:
            let genre = (pick("reading.genre").first ?? otherText("reading.genre_other"))
            let dose = (pick("reading.dose").first ?? otherText("reading.dose_other"))
            let barrier = (pick("reading.barrier").first ?? otherText("reading.barrier_other"))

            var steps: [String] = []
            steps.append("把書放到手邊")
            steps.append("打開書到下一頁")
            if barrier.contains("分心") {
                steps.append("把手機放遠一點（先5分鐘）")
            } else {
                steps.append("坐好，讓眼睛對準書頁10秒")
            }

            // dose: pick exactly one
            if !dose.isEmpty {
                steps.append("讀\(dose)")
            } else {
                steps.append("讀1段（或1頁）")
            }

            steps.append("用一句話回想：剛剛在講什麼？")
            steps.append("把最喜歡的一句抄下來")
            steps.append(genre.isEmpty ? "把這本書加入『想讀/在讀』清單" : "把這本\(genre)加入『想讀/在讀』清單")
            steps.append("把明天要讀的頁碼寫在書籤上")
            return dedupe(steps)
        }
    }
}
