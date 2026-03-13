import Foundation
import SwiftUI
import Combine

@MainActor
final class BingoHomeViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var selectedHabitId: UUID = UUID()
    @Published var board: BingoBoard? = nil

    @Published var showCheckIn: Bool = false
    @Published var showHabitSetup: Bool = false

    // pending checkin values
    @Published var pendingMood: Double = 0.5
    @Published var pendingDrive: Double = 0.5
    @Published var pendingYesterdayDifficulty: Double = 0.5

    struct HeaderCopy {
        let title: String
        let subtitle: String
    }

    @Published var headerCopy: HeaderCopy? = nil

    private let resetHour = 4

    private var dateKey: String {
        DateKey.todayKey(resetHour: resetHour)
    }

    func bootstrap() async {
        await loadHabits()
        if let core = habits.first(where: { $0.isCore }) {
            selectedHabitId = core.id
        } else if let first = habits.first {
            selectedHabitId = first.id
        }

        // Show check-in once per date key
        if await LocalStore.shared.loadDailyState(dateKey: dateKey) == nil {
            showCheckIn = true
        } else {
            await loadOrGenerateBoard()
        }
    }

    func loadHabits() async {
        habits = await LocalStore.shared.loadHabits()
        if habits.isEmpty {
            // keep selection stable
            selectedHabitId = UUID()
        }
    }

    func addHabit(_ habit: Habit) {
        Task {
            var next = await LocalStore.shared.loadHabits()
            // Only one core habit for MVP: if new is core, unset others.
            if habit.isCore {
                next = next.map { h in
                    var m = h
                    m.isCore = false
                    return m
                }
            }
            next.append(habit)
            await LocalStore.shared.saveHabits(next)
            await loadHabits()
            selectedHabitId = habit.id
            await loadOrGenerateBoard(force: true)
        }
    }

    func saveCheckIn(mood: Double, drive: Double, yesterdayDifficulty: Double) {
        Task {
            let state = DailyState(dateKey: dateKey, mood: mood, drive: drive, yesterdayDifficulty: yesterdayDifficulty)
            await LocalStore.shared.saveDailyState(state)
            showCheckIn = false
            await loadOrGenerateBoard(force: true)
        }
    }

    func skipCheckIn() {
        Task {
            // Save defaults to avoid re-prompting
            let state = DailyState(dateKey: dateKey, mood: pendingMood, drive: pendingDrive, yesterdayDifficulty: pendingYesterdayDifficulty)
            await LocalStore.shared.saveDailyState(state)
            showCheckIn = false
            await loadOrGenerateBoard(force: true)
        }
    }

    func loadOrGenerateBoard(force: Bool = false) async {
        guard let habit = habits.first(where: { $0.id == selectedHabitId }) else {
            board = nil
            return
        }

        let core = habits.first(where: { $0.isCore })
        let state = await LocalStore.shared.loadDailyState(dateKey: dateKey) ?? DailyState(dateKey: dateKey, mood: 0.5, drive: 0.5, yesterdayDifficulty: 0.5)

        // v0 header copy
        let level = BingoGenerator.stateLevel(mood: state.mood, drive: state.drive)
        switch level {
        case .low:
            headerCopy = HeaderCopy(title: "今天先點亮一小格也很好", subtitle: "花園不急，我們先從最輕的開始。")
        case .mid:
            headerCopy = HeaderCopy(title: "今天可以慢慢往前走", subtitle: "做一點點，也是在照顧想成長的自己。")
        case .high:
            headerCopy = HeaderCopy(title: "今天的你，已經準備好再走遠一點", subtitle: "把想做的事拆小，花園會記得每一步。")
        }

        if !force, let existing = await LocalStore.shared.loadBoard(habitId: habit.id, dateKey: dateKey) {
            board = existing
            return
        }

        let generated = BingoGenerator.generateBoard(
            habit: habit,
            coreHabit: core,
            dateKey: dateKey,
            mood: state.mood,
            drive: state.drive,
            yesterdayDifficulty: state.yesterdayDifficulty
        )
        await LocalStore.shared.saveBoard(generated)
        board = generated
    }

    func toggle(index: Int) {
        guard var b = board else { return }
        guard b.checked.indices.contains(index) else { return }
        b.checked[index].toggle()
        board = b
        Task { await LocalStore.shared.saveBoard(b) }
    }
}
