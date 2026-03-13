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
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)

                FlowLayout(spacing: 8) {
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
        }
    }
}

// Simple flow layout for chips
private struct FlowLayout<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            self.generate(in: geo)
        }
        .frame(minHeight: 1)
    }

    private func generate(in geo: GeometryProxy) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            content
                .alignmentGuide(.leading) { d in
                    if (abs(x - d.width) > geo.size.width) {
                        x = 0
                        y -= d.height + spacing
                    }
                    let result = x
                    x -= d.width + spacing
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = y
                    return result
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
