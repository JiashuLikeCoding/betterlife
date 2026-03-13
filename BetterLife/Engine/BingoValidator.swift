import Foundation

enum BingoValidator {

    static func isValidTaskText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let count = trimmed.count
        guard (6...18).contains(count) else { return false }

        for phrase in ForbiddenPhrases.list {
            if trimmed.contains(phrase) { return false }
        }
        // Hard ban fuzzy tokens (kept small; can be extended)
        for token in ForbiddenPhrases.fuzzyTokens {
            if trimmed.contains(token) { return false }
        }

        return true
    }

    static func hasAtLeastOne4StepPath(_ tasks: [BingoTask]) -> Bool {
        let grouped = Dictionary(grouping: tasks.compactMap { t -> (String, Int)? in
            guard let g = t.pathGroup, let s = t.pathStep else { return nil }
            return (g, s)
        }, by: { $0.0 })

        for (_, pairs) in grouped {
            let steps = Set(pairs.map { $0.1 })
            if steps.contains(1) && steps.contains(2) && steps.contains(3) && steps.contains(4) {
                return true
            }
        }
        return false
    }

    static func uniqueActionObjectKey(_ text: String) -> String {
        // Lightweight heuristic: normalize digits + punctuation
        let lowered = text
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // remove numbers to reduce trivial variants
        let noNums = lowered.replacingOccurrences(of: "[0-9０-９]", with: "", options: .regularExpression)
        return noNums
    }

    static func boardHasNoDuplicates(_ tasks: [BingoTask]) -> Bool {
        var seen = Set<String>()
        for t in tasks {
            let key = uniqueActionObjectKey(t.text)
            if seen.contains(key) { return false }
            seen.insert(key)
        }
        return true
    }

    static func validateBoard(_ tasks: [BingoTask]) -> [String] {
        var errors: [String] = []
        if tasks.count != 16 { errors.append("total_16_tasks") }
        if !tasks.allSatisfy({ isValidTaskText($0.text) }) { errors.append("task_text_invalid") }
        if !boardHasNoDuplicates(tasks) { errors.append("no_duplicate") }
        if !hasAtLeastOne4StepPath(tasks) { errors.append("has_path_group") }
        return errors
    }
}
