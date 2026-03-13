import SwiftUI

struct BingoBoardView: View {
    let board: BingoBoard
    let onToggle: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(board.tasks.enumerated()), id: \.offset) { index, task in
                BingoCell(
                    text: task.text,
                    checked: board.checked.indices.contains(index) ? board.checked[index] : false,
                    source: task.source
                ) {
                    onToggle(index)
                }
            }
        }
    }
}

private struct BingoCell: View {
    let text: String
    let checked: Bool
    let source: TaskSource
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(source.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(checked ? .green : .secondary)
                }

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(height: 96)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.black.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        // Low-saturation “Morandi-ish” hints
        switch source {
        case .selfLove:
            return Color(red: 0.94, green: 0.92, blue: 0.90)
        case .habit:
            return Color(red: 0.90, green: 0.93, blue: 0.95)
        case .coreHabit:
            return Color(red: 0.91, green: 0.95, blue: 0.91)
        case .selfGrowth:
            return Color(red: 0.95, green: 0.92, blue: 0.96)
        }
    }
}
