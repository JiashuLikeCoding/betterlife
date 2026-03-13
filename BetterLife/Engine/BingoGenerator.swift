import Foundation

struct Recipe {
    var selfLoveCount: Int
    var habitCount: Int
}

enum BingoGenerator {

    /// Minimal ordered set for stable de-duplication.
    private struct OrderedSet<T: Hashable> {
        private(set) var elements: [T] = []
        private var set: Set<T> = []

        init(_ items: [T]) {
            for i in items { append(i) }
        }

        mutating func append(_ item: T) {
            guard !set.contains(item) else { return }
            set.insert(item)
            elements.append(item)
        }
    }

    // v0 confirmed
    static func stateLevel(mood: Double, drive: Double) -> StateLevel {
        let state = (mood + drive) / 2.0
        if state < 0.34 { return .low }
        if state <= 0.67 { return .mid }
        return .high
    }

    static func recipe(for level: StateLevel) -> Recipe {
        switch level {
        case .low:
            return Recipe(selfLoveCount: 14, habitCount: 2)
        case .mid:
            return Recipe(selfLoveCount: 6, habitCount: 10)
        case .high:
            return Recipe(selfLoveCount: 2, habitCount: 14)
        }
    }

    static func generateBoard(
        habit: Habit,
        coreHabit: Habit?,
        dateKey: String,
        mood: Double,
        drive: Double,
        yesterdayDifficulty: Double
    ) -> BingoBoard {
        let level = stateLevel(mood: mood, drive: drive)
        let baseRecipe = recipe(for: level)

        let (seedString, seed64) = Seed.boardSeed(habitId: habit.id, dateKey: dateKey)
        var rng = SeededRandomNumberGenerator(seed: seed64)

        // Build candidate pools
        var selfLovePool = TaskLibrary.selfLove
        selfLovePool.shuffle(using: &rng)

        // Habit tasks MUST come from the user's habit-specific microSteps.
        // Build a 4-step "path" from the first unique steps (always relevant).
        var habitSteps = habit.microSteps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // If user hasn't curated enough steps yet, auto-supplement from local "AI" to reduce repetition.
        if habitSteps.count < 10 {
            habitSteps.append(contentsOf: AIStepSuggester.suggestMicroSteps(habitName: habit.habitName))
        }
        habitSteps = OrderedSet(habitSteps).elements

        let pathGroupId = "habit_\(habit.id.uuidString.prefix(6))"
        let uniquePathSteps = Array(OrderedSet(habitSteps).elements.prefix(4))
        let path: [BingoTask] = uniquePathSteps.enumerated().map { (idx, text) in
            let step = idx + 1
            let tier: DifficultyTier = {
                switch step {
                case 1, 2: return .micro
                case 3: return .easy
                default: return .rewarding
                }
            }()
            return BingoTask(
                id: "micro_path_\(step)",
                text: text,
                source: .habit,
                tier: tier,
                pathGroup: pathGroupId,
                pathStep: step
            )
        }

        // If there is a core habit different from current habit, add its starter step as optional micro
        let coreStarter: String? = {
            guard let core = coreHabit, core.id != habit.id else { return nil }
            return core.microSteps.first ?? core.starterStep
        }()

        // Determine habit slots sources (habit vs core_habit)
        var habitCount = baseRecipe.habitCount
        var selfLoveCount = baseRecipe.selfLoveCount
        if habitCount + selfLoveCount != 16 {
            // safety
            habitCount = 16 - selfLoveCount
        }

        // yesterday_difficulty only affects tier, not ratio
        let tooHard = yesterdayDifficulty > 0.67
        let tooEasy = yesterdayDifficulty < 0.34

        // In low state: both habit tasks must be micro; at least 1 is starter_step / path step 1
        let enforceLowMicro = (level == .low)

        // Compose tasks
        var tasks: [BingoTask] = []

        // 1) Ensure at least one 4-step path is included
        // - low: use a SELF-LOVE 4-step path (to keep ratio stable and avoid forcing many habit tasks)
        // - mid/high: use the HABIT 4-step path
        let pathTasks: [BingoTask]
        if level == .low {
            let selfLovePath = pickSelfLovePath(using: &rng, tooHard: tooHard, tooEasy: tooEasy)
            pathTasks = selfLovePath
        } else {
            // Adjust tiers based on yesterday difficulty, but keep the same 4 steps.
            pathTasks = path.map { t in
                var m = t
                m.tier = adjustTier(t.tier, tooHard: tooHard, tooEasy: tooEasy)
                return m
            }
        }
        tasks.append(contentsOf: pathTasks)

        // Adjust remaining counts after including path
        // Count habit tasks already used in the included path.
        let usedHabitInPath = pathTasks.filter { $0.source == .habit }.count
        let usedSelfLoveInPath = pathTasks.filter { $0.source == .selfLove }.count

        var remainingHabit = max(0, habitCount - usedHabitInPath)
        var remainingSelfLove = max(0, selfLoveCount - usedSelfLoveInPath)

        var remainingSlots = 16 - tasks.count

        // Keep ratios stable; if path consumed more slots, reduce the other bucket to fit.
        if remainingSlots < remainingSelfLove + remainingHabit {
            let overflow = (remainingSelfLove + remainingHabit) - remainingSlots
            remainingSelfLove = max(0, remainingSelfLove - overflow)
        }

        // 2) Fill habit slots (micro steps)
        if remainingSlots > 0 && remainingHabit > 0 {
            var pool = habit.microSteps
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if let coreStarter {
                pool.append(coreStarter)
            }

            if pool.isEmpty {
                pool = [habit.starterStep]
            }

            // Avoid repeating steps already placed in the board
            let already = Set(tasks.map { $0.text })
            pool = pool.filter { !already.contains($0) }

            pool.shuffle(using: &rng)

            for (i, text) in pool.prefix(remainingHabit).enumerated() {
                tasks.append(BingoTask(id: "micro_\(i)", text: text, source: .habit, tier: .micro, pathGroup: nil, pathStep: nil))
            }
            remainingSlots = 16 - tasks.count
        }

        // 3) Fill self-love slots
        if remainingSlots > 0 && remainingSelfLove > 0 {
            for tpl in selfLovePool {
                if tasks.count >= 16 { break }
                if remainingSelfLove <= 0 { break }
                let adjustedTier = adjustTier(tpl.tier, tooHard: tooHard, tooEasy: tooEasy)
                tasks.append(BingoTask(id: tpl.id, text: tpl.text, source: .selfLove, tier: adjustedTier, pathGroup: tpl.pathGroup, pathStep: tpl.pathStep))
                remainingSelfLove -= 1
            }
        }

        // 4) If still not 16, fill with habit micro steps (always relevant)
        if tasks.count < 16 {
            var fallback = habit.microSteps
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if fallback.isEmpty {
                fallback = [habit.starterStep]
            }

            var i = 0
            while tasks.count < 16 {
                let text = fallback[i % fallback.count]
                tasks.append(BingoTask(id: "habit_fallback_\(i)", text: text, source: .habit, tier: .micro, pathGroup: nil, pathStep: nil))
                i += 1
            }
        }

        // 5) Enforce low-state habit rules
        if enforceLowMicro {
            // In low: habitCount is 2.
            // - both must be micro
            // - at least 1 must be starter_step (path step 1)
            var habitIndices = tasks.indices.filter { tasks[$0].source == .habit }
            habitIndices.sort()

            // Ensure we have at least 2 habit tasks; if not, append starter suggestions.
            while habitIndices.count < 2 {
                let suggestion = habit.microSteps.first ?? habit.starterStep
                let idx = tasks.count
                tasks.append(BingoTask(id: "habit_fill_\(idx)", text: suggestion, source: .habit, tier: .micro, pathGroup: nil, pathStep: nil))
                habitIndices.append(idx)
            }

            // Force micro tiers
            tasks[habitIndices[0]].tier = .micro
            tasks[habitIndices[1]].tier = .micro

            // Ensure starter_step is present in one of the two slots
            let starter = habit.starterStep
            if !(tasks[habitIndices[0]].text == starter || tasks[habitIndices[1]].text == starter) {
                tasks[habitIndices[0]] = BingoTask(id: "starter_step", text: starter, source: .habit, tier: .micro, pathGroup: "habit_\(habit.id.uuidString.prefix(6))", pathStep: 1)
            }
        }

        // 6) Final validation and replacements
        tasks = Array(tasks.prefix(16))
        tasks = replaceInvalid(tasks: tasks, habit: habit, seed: &rng, tooHard: tooHard, tooEasy: tooEasy)

        let board = BingoBoard(habitId: habit.id, dateKey: dateKey, boardSeed: seedString, tasks: tasks)
        return board
    }

    private static func pickSelfLovePath(using rng: inout SeededRandomNumberGenerator, tooHard: Bool, tooEasy: Bool) -> [BingoTask] {
        // Pick a self-love path group that has steps 1..4
        var pool = TaskLibrary.selfLove.filter { $0.pathGroup != nil && $0.pathStep != nil }
        pool.shuffle(using: &rng)
        let grouped = Dictionary(grouping: pool, by: { $0.pathGroup! })
        guard let (g, items) = grouped.first(where: { (_, items) in
            let steps = Set(items.compactMap { $0.pathStep })
            return steps.contains(1) && steps.contains(2) && steps.contains(3) && steps.contains(4)
        }) else {
            // fallback minimal path
            return [
                BingoTask(id: "sl_micro_breathe3", text: "坐好，深呼吸三次", source: .selfLove, tier: .micro, pathGroup: "sl_ground", pathStep: 1),
                BingoTask(id: "sl_micro_water3", text: "喝三口溫水", source: .selfLove, tier: .micro, pathGroup: "sl_ground", pathStep: 2),
                BingoTask(id: "sl_micro_closeeyes30", text: "閉眼感受呼吸30秒", source: .selfLove, tier: .micro, pathGroup: "sl_ground", pathStep: 3),
                BingoTask(id: "sl_micro_open_window", text: "打開窗呼吸一口氣", source: .selfLove, tier: .micro, pathGroup: "sl_ground", pathStep: 4)
            ]
        }

        let path = (1...4).compactMap { step in items.first(where: { $0.pathStep == step }) }
        return path.map { tpl in
            BingoTask(
                id: tpl.id,
                text: tpl.text,
                source: .selfLove,
                tier: adjustTier(tpl.tier, tooHard: tooHard, tooEasy: tooEasy),
                pathGroup: g,
                pathStep: tpl.pathStep
            )
        }
    }

    private static func adjustTier(_ tier: DifficultyTier, tooHard: Bool, tooEasy: Bool) -> DifficultyTier {
        // yesterday_difficulty affects tier only
        if tooHard {
            switch tier {
            case .rewarding: return .easy
            case .easy: return .micro
            case .micro: return .micro
            }
        }
        if tooEasy {
            switch tier {
            case .micro: return .micro
            case .easy: return .rewarding
            case .rewarding: return .rewarding
            }
        }
        return tier
    }

    private static func replaceInvalid(
        tasks: [BingoTask],
        habit: Habit,
        seed: inout SeededRandomNumberGenerator,
        tooHard: Bool,
        tooEasy: Bool
    ) -> [BingoTask] {
        var result = tasks

        func pickSelfLoveReplacement() -> BingoTask {
            var pool = TaskLibrary.selfLove
            pool.shuffle(using: &seed)
            for tpl in pool {
                if BingoValidator.isValidTaskText(tpl.text) {
                    let t = BingoTask(id: tpl.id, text: tpl.text, source: .selfLove, tier: adjustTier(tpl.tier, tooHard: tooHard, tooEasy: tooEasy), pathGroup: tpl.pathGroup, pathStep: tpl.pathStep)
                    return t
                }
            }
            return BingoTask(id: "sl_fallback", text: "坐好，深呼吸三次", source: .selfLove, tier: .micro, pathGroup: "sl_ground", pathStep: 1)
        }

        func pickHabitReplacement() -> BingoTask {
            let path = TaskLibrary.habitPathGroup(for: habit)
            var pool = path
            pool.shuffle(using: &seed)
            for tpl in pool {
                if BingoValidator.isValidTaskText(tpl.text) {
                    return BingoTask(id: tpl.id, text: tpl.text, source: .habit, tier: adjustTier(tpl.tier, tooHard: tooHard, tooEasy: tooEasy), pathGroup: tpl.pathGroup, pathStep: tpl.pathStep)
                }
            }
            let fallback = TaskLibrary.starterSuggestions(for: habit.habitType).first ?? "打開文章讀第一段"
            return BingoTask(id: "habit_fallback", text: fallback, source: .habit, tier: .micro, pathGroup: nil, pathStep: nil)
        }

        // Replace invalid texts
        for i in result.indices {
            if !BingoValidator.isValidTaskText(result[i].text) {
                result[i] = (result[i].source == .selfLove) ? pickSelfLoveReplacement() : pickHabitReplacement()
            }
        }

        // Ensure no duplicates
        var attempts = 0
        while !BingoValidator.boardHasNoDuplicates(result) && attempts < 5 {
            attempts += 1
            // Replace one duplicate
            var seen = Set<String>()
            var replaced = false
            for i in result.indices {
                let key = BingoValidator.uniqueActionObjectKey(result[i].text)
                if seen.contains(key) {
                    result[i] = (result[i].source == .selfLove) ? pickSelfLoveReplacement() : pickHabitReplacement()
                    replaced = true
                    break
                }
                seen.insert(key)
            }
            if !replaced { break }
        }

        // Ensure has at least one 4-step path group
        if !BingoValidator.hasAtLeastOne4StepPath(result) {
            // Prefer a self-love path as safe fallback
            var pool = TaskLibrary.selfLove.filter { $0.pathGroup != nil && $0.pathStep != nil }
            pool.shuffle(using: &seed)
            let grouped = Dictionary(grouping: pool, by: { $0.pathGroup! })
            if let (g, items) = grouped.first(where: { (_, items) in
                let steps = Set(items.compactMap { $0.pathStep })
                return steps.contains(1) && steps.contains(2) && steps.contains(3) && steps.contains(4)
            }) {
                let path = (1...4).compactMap { step in items.first(where: { $0.pathStep == step }) }
                for (idx, tpl) in path.enumerated() {
                    if idx < result.count {
                        result[idx] = BingoTask(id: tpl.id, text: tpl.text, source: .selfLove, tier: adjustTier(tpl.tier, tooHard: tooHard, tooEasy: tooEasy), pathGroup: g, pathStep: tpl.pathStep)
                    }
                }
            }
        }

        return result
    }
}
