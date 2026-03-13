import SwiftUI

struct CoachQuestionViews {

    static func inferKind(from habitName: String) -> CoachHabitKind? {
        let s = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        let n = s.lowercased()

        if n.contains("運動") || n.contains("健身") || n.contains("瑜伽") || n.contains("跑") || n.contains("慢跑") || n.contains("伸展") || n.contains("拉伸") {
            return .exercise
        }
        if n.contains("睡") || n.contains("眠") || n.contains("早睡") || n.contains("上床") {
            return .sleep
        }
        if n.contains("早起") || n.contains("起床") {
            return .wake
        }
        if n.contains("讀") || n.contains("閱讀") || n.contains("看書") || n.contains("書") {
            return .reading
        }
        return nil
    }

    struct ChipsRow: View {
        var title: String
        var options: [String]
        var allowsMultiple: Bool
        var selection: Binding<Set<String>>
        var otherText: Binding<String>
        var otherPlaceholder: String = "其他…"

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.subheadline)

                WrapLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(options, id: \.self) { opt in
                        Chip(title: opt, selected: selection.wrappedValue.contains(opt)) {
                            if allowsMultiple {
                                if selection.wrappedValue.contains(opt) {
                                    selection.wrappedValue.remove(opt)
                                } else {
                                    selection.wrappedValue.insert(opt)
                                }
                            } else {
                                if selection.wrappedValue.contains(opt) {
                                    selection.wrappedValue.removeAll()
                                } else {
                                    selection.wrappedValue = [opt]
                                }
                            }
                        }
                    }
                }

                TextField(otherPlaceholder, text: otherText)
                    .textInputAutocapitalization(.never)
            }
            .padding(.vertical, 2)
        }
    }
}

/// Stable wrap layout for chips (iOS 16+)
private struct WrapLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0 && (x + s.width) > maxWidth {
                y += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
            }
            rowHeight = max(rowHeight, s.height)
            x += s.width
            usedWidth = max(usedWidth, x)
            x += spacing
        }

        return CGSize(width: maxWidth > 0 ? maxWidth : usedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX && (x + s.width) > bounds.maxX {
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: s.width, height: s.height))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
