import Foundation

struct Habit: Codable, Identifiable, Equatable {
    var id: UUID
    var habitName: String
    var habitType: HabitType
    var stage: HabitStage
    var mainBarrier: MainBarrier
    var isCore: Bool

    /// 30秒內、單一動作、可判斷完成
    var starterStep: String
    var contextHint: String
    var successDefinition: String
    var freeNote: String

    /// Used to reduce repeats over time
    var recentTaskIds: [String]
    var recentBoardHashes: [String]

    init(
        id: UUID = UUID(),
        habitName: String,
        habitType: HabitType,
        stage: HabitStage,
        mainBarrier: MainBarrier,
        isCore: Bool,
        starterStep: String,
        contextHint: String = "日常最順手的時間",
        successDefinition: String = "完成第一步就算做到",
        freeNote: String = "",
        recentTaskIds: [String] = [],
        recentBoardHashes: [String] = []
    ) {
        self.id = id
        self.habitName = habitName
        self.habitType = habitType
        self.stage = stage
        self.mainBarrier = mainBarrier
        self.isCore = isCore
        self.starterStep = starterStep
        self.contextHint = contextHint
        self.successDefinition = successDefinition
        self.freeNote = freeNote
        self.recentTaskIds = recentTaskIds
        self.recentBoardHashes = recentBoardHashes
    }
}

struct DailyState: Codable, Equatable {
    var dateKey: String
    var mood: Double // 0..1
    var drive: Double // 0..1
    var yesterdayDifficulty: Double // 0..1
}

struct BingoTask: Codable, Identifiable, Equatable {
    var id: String
    var text: String
    var source: TaskSource
    var tier: DifficultyTier
    var pathGroup: String? // used by validator
    var pathStep: Int? // 1..4
}

struct BingoBoard: Codable, Equatable {
    var habitId: UUID
    var dateKey: String
    var boardSeed: String

    var tasks: [BingoTask] // 16
    var checked: [Bool] // 16

    init(habitId: UUID, dateKey: String, boardSeed: String, tasks: [BingoTask], checked: [Bool]? = nil) {
        self.habitId = habitId
        self.dateKey = dateKey
        self.boardSeed = boardSeed
        self.tasks = tasks
        self.checked = checked ?? Array(repeating: false, count: tasks.count)
    }
}
