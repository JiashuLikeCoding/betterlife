import Foundation

enum HabitType: String, Codable, CaseIterable, Identifiable {
    case bodyHealth = "body_health"
    case knowledge
    case skill
    case environment
    case emotionCare = "emotion_care"
    case focusExecution = "focus_execution"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bodyHealth: return "身體健康"
        case .knowledge: return "知識吸收"
        case .skill: return "技能掌握"
        case .environment: return "環境整理"
        case .emotionCare: return "情緒照顧"
        case .focusExecution: return "專注執行"
        }
    }
}

enum HabitStage: String, Codable, CaseIterable, Identifiable {
    case zeroStart = "zero_start"
    case starting
    case hasBase = "has_base"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zeroStart: return "零開始"
        case .starting: return "剛開始"
        case .hasBase: return "已有基礎"
        }
    }
}

enum MainBarrier: String, Codable, CaseIterable, Identifiable {
    case noTime = "no_time"
    case fearHard = "fear_hard"
    case forgetful
    case lowMood = "low_mood"
    case dontKnowHow = "dont_know_how"
    case lowMotivation = "low_motivation"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .noTime: return "沒時間"
        case .fearHard: return "怕難"
        case .forgetful: return "容易忘"
        case .lowMood: return "情緒低落"
        case .dontKnowHow: return "不知如何開始"
        case .lowMotivation: return "低動機"
        }
    }
}

enum TaskSource: String, Codable {
    case selfLove = "self_love"
    case habit
    case coreHabit = "core_habit"
    case selfGrowth = "self_growth" // future

    var displayName: String {
        switch self {
        case .selfLove: return "自愛"
        case .habit: return "習慣"
        case .coreHabit: return "核心"
        case .selfGrowth: return "進步"
        }
    }
}

enum DifficultyTier: String, Codable {
    case micro
    case easy
    case rewarding
}

enum StateLevel: String, Codable {
    case low
    case mid
    case high
}
