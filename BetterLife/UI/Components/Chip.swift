import SwiftUI

struct Chip: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Color.blue.opacity(0.18) : Color.gray.opacity(0.12))
                .foregroundStyle(selected ? Color.blue : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
