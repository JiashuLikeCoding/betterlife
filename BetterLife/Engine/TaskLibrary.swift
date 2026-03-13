import Foundation

struct TaskTemplate {
    let id: String
    let text: String
    let tier: DifficultyTier
    let pathGroup: String?
    let pathStep: Int?
}

enum TaskLibrary {

    // MARK: Self-love (自愛)

    static let selfLove: [TaskTemplate] = [
        // micro
        .init(id: "sl_micro_breathe3", text: "坐好，深呼吸三次", tier: .micro, pathGroup: "sl_ground", pathStep: 1),
        .init(id: "sl_micro_water3", text: "喝三口溫水", tier: .micro, pathGroup: "sl_ground", pathStep: 2),
        .init(id: "sl_micro_stretch30", text: "伸展肩頸30秒", tier: .micro, pathGroup: "sl_body", pathStep: 1),
        .init(id: "sl_micro_closeeyes30", text: "閉眼感受呼吸30秒", tier: .micro, pathGroup: "sl_ground", pathStep: 3),
        .init(id: "sl_micro_text1line", text: "寫下一句：我可以慢慢來", tier: .micro, pathGroup: "sl_kind", pathStep: 1),
        .init(id: "sl_micro_phone_silent", text: "把手機靜音5分鐘", tier: .micro, pathGroup: "sl_focus", pathStep: 1),
        .init(id: "sl_micro_open_window", text: "打開窗呼吸一口氣", tier: .micro, pathGroup: "sl_ground", pathStep: 4),

        // easy
        .init(id: "sl_easy_clear_space", text: "清出桌面一小格", tier: .easy, pathGroup: "sl_space", pathStep: 1),
        .init(id: "sl_easy_put_one_back", text: "把一樣物品放回原位", tier: .easy, pathGroup: "sl_space", pathStep: 2),
        .init(id: "sl_easy_write_mood", text: "把今天心情寫一行", tier: .easy, pathGroup: "sl_kind", pathStep: 2),
        .init(id: "sl_easy_wash_face", text: "用冷水洗一洗臉", tier: .easy, pathGroup: "sl_body", pathStep: 2),
        .init(id: "sl_easy_make_tea", text: "泡一杯熱茶或溫水", tier: .easy, pathGroup: "sl_body", pathStep: 3),
        .init(id: "sl_easy_walk_room", text: "在房間走一圈再坐下", tier: .easy, pathGroup: "sl_body", pathStep: 4),

        // rewarding (still small)
        .init(id: "sl_reward_note_3things", text: "寫下三樣值得感謝的小事", tier: .rewarding, pathGroup: "sl_grat", pathStep: 1),
        .init(id: "sl_reward_shower_quick", text: "沖個快速熱水澡", tier: .rewarding, pathGroup: "sl_body", pathStep: 5),
        .init(id: "sl_reward_plan_tomorrow", text: "替明天留一個好開始", tier: .rewarding, pathGroup: "sl_focus", pathStep: 2)
    ]

    // MARK: Habit path groups (起手式 4-step)

    static func habitPathGroup(for habit: Habit) -> [TaskTemplate] {
        // Build a 4-step path (micro->micro/easy->easy->easy/rewarding)
        // Must be concrete, type-driven.
        let g = "habit_\(habit.id.uuidString.prefix(6))"

        switch habit.habitType {
        case .knowledge:
            return [
                .init(id: "hp_k_1", text: habit.starterStep, tier: .micro, pathGroup: g, pathStep: 1),
                .init(id: "hp_k_2", text: "讀第二段，畫一條重點", tier: .easy, pathGroup: g, pathStep: 2),
                .init(id: "hp_k_3", text: "寫一句重點在筆記", tier: .easy, pathGroup: g, pathStep: 3),
                .init(id: "hp_k_4", text: "存一個標籤方便下次", tier: .rewarding, pathGroup: g, pathStep: 4)
            ]
        case .skill:
            return [
                .init(id: "hp_s_1", text: habit.starterStep, tier: .micro, pathGroup: g, pathStep: 1),
                .init(id: "hp_s_2", text: "再做一次，放慢節奏", tier: .easy, pathGroup: g, pathStep: 2),
                .init(id: "hp_s_3", text: "錄下10秒成果作對照", tier: .easy, pathGroup: g, pathStep: 3),
                .init(id: "hp_s_4", text: "寫下下一步要改一點", tier: .rewarding, pathGroup: g, pathStep: 4)
            ]
        case .bodyHealth:
            return [
                .init(id: "hp_b_1", text: habit.starterStep, tier: .micro, pathGroup: g, pathStep: 1),
                .init(id: "hp_b_2", text: "站起伸展30秒", tier: .micro, pathGroup: g, pathStep: 2),
                .init(id: "hp_b_3", text: "走到門口再走回來", tier: .easy, pathGroup: g, pathStep: 3),
                .init(id: "hp_b_4", text: "喝水並記一個勾", tier: .easy, pathGroup: g, pathStep: 4)
            ]
        case .environment:
            return [
                .init(id: "hp_e_1", text: habit.starterStep, tier: .micro, pathGroup: g, pathStep: 1),
                .init(id: "hp_e_2", text: "把兩樣物品放回原位", tier: .easy, pathGroup: g, pathStep: 2),
                .init(id: "hp_e_3", text: "丟掉一樣不要的東西", tier: .easy, pathGroup: g, pathStep: 3),
                .init(id: "hp_e_4", text: "擦一下桌面那一格", tier: .rewarding, pathGroup: g, pathStep: 4)
            ]
        case .emotionCare:
            return [
                .init(id: "hp_m_1", text: habit.starterStep, tier: .micro, pathGroup: g, pathStep: 1),
                .init(id: "hp_m_2", text: "把感受寫成五個字", tier: .easy, pathGroup: g, pathStep: 2),
                .init(id: "hp_m_3", text: "寫一句：我會照顧自己", tier: .easy, pathGroup: g, pathStep: 3),
                .init(id: "hp_m_4", text: "替自己倒一杯溫水", tier: .easy, pathGroup: g, pathStep: 4)
            ]
        case .focusExecution:
            return [
                .init(id: "hp_f_1", text: habit.starterStep, tier: .micro, pathGroup: g, pathStep: 1),
                .init(id: "hp_f_2", text: "打開待辦圈出最小一步", tier: .easy, pathGroup: g, pathStep: 2),
                .init(id: "hp_f_3", text: "設5分鐘計時器開始", tier: .easy, pathGroup: g, pathStep: 3),
                .init(id: "hp_f_4", text: "完成後打個勾就收工", tier: .rewarding, pathGroup: g, pathStep: 4)
            ]
        }
    }

    static func starterSuggestions(for habitType: HabitType, habitName: String? = nil) -> [String] {
        let name = (habitName ?? "").replacingOccurrences(of: " ", with: "")
        // Sleep-related heuristics
        if name.contains("睡") || name.contains("眠") || name.contains("上床") || name.contains("早睡") {
            return [
                "把手機放遠一點",
                "把燈光調暗一點",
                "設定明天鬧鐘",
                "把明天衣服放好"
            ]
        }

        switch habitType {
        case .bodyHealth:
            return ["倒一杯水放手邊", "穿上運動鞋"]
        case .knowledge:
            return ["打開文章讀第一段", "翻到書第一頁"]
        case .skill:
            return ["打開工具做最基本動作", "寫第一行"]
        case .environment:
            return ["清出桌面一小格", "把一樣物品放回原位"]
        case .emotionCare:
            return ["坐好深呼吸三次", "閉眼感受呼吸30秒"]
        case .focusExecution:
            return ["把手機靜音5分鐘", "打開待辦清單"]
        }
    }
}
