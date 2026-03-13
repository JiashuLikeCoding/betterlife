import Foundation

enum CoachHabitKind: String, Codable {
    case exercise
    case sleep
    case wake
    case reading
}

struct CoachProfile: Codable, Equatable {
    var kind: CoachHabitKind

    // Generic storage: small, flexible, forward-compatible.
    // Keys are stable, values are user selections.
    var answers: [String: [String]]
    var otherText: [String: String]

    init(kind: CoachHabitKind, answers: [String: [String]] = [:], otherText: [String: String] = [:]) {
        self.kind = kind
        self.answers = answers
        self.otherText = otherText
    }
}
