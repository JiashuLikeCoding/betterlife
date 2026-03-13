import Foundation

actor LocalStore {
    static let shared = LocalStore()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    private func docsURL() throws -> URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "LocalStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing documents directory"]) 
        }
        return url
    }

    private func habitsURL() throws -> URL {
        try docsURL().appendingPathComponent("habits.json")
    }

    private func dailyStateURL(dateKey: String) throws -> URL {
        try docsURL().appendingPathComponent("daily_state_\(dateKey).json")
    }

    private func boardURL(habitId: UUID, dateKey: String) throws -> URL {
        let dir = try docsURL().appendingPathComponent("boards", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("board_\(habitId.uuidString)_\(dateKey).json")
    }

    // MARK: Habits

    func loadHabits() -> [Habit] {
        do {
            let url = try habitsURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return [] }
            let data = try Data(contentsOf: url)
            return try decoder.decode([Habit].self, from: data)
        } catch {
            return []
        }
    }

    func saveHabits(_ habits: [Habit]) {
        do {
            let url = try habitsURL()
            let data = try encoder.encode(habits)
            try data.write(to: url, options: [.atomic])
        } catch {
            // swallow (MVP)
        }
    }

    // MARK: DailyState

    func loadDailyState(dateKey: String) -> DailyState? {
        do {
            let url = try dailyStateURL(dateKey: dateKey)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            return try decoder.decode(DailyState.self, from: data)
        } catch {
            return nil
        }
    }

    func saveDailyState(_ state: DailyState) {
        do {
            let url = try dailyStateURL(dateKey: state.dateKey)
            let data = try encoder.encode(state)
            try data.write(to: url, options: [.atomic])
        } catch {
            // swallow
        }
    }

    // MARK: Board

    func loadBoard(habitId: UUID, dateKey: String) -> BingoBoard? {
        do {
            let url = try boardURL(habitId: habitId, dateKey: dateKey)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            return try decoder.decode(BingoBoard.self, from: data)
        } catch {
            return nil
        }
    }

    func saveBoard(_ board: BingoBoard) {
        do {
            let url = try boardURL(habitId: board.habitId, dateKey: board.dateKey)
            let data = try encoder.encode(board)
            try data.write(to: url, options: [.atomic])
        } catch {
            // swallow
        }
    }
}
