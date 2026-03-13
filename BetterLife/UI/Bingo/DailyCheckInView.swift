import SwiftUI

struct DailyCheckInView: View {
    @State var mood: Double
    @State var drive: Double
    @State var difficulty: Double

    var onSave: (Double, Double, Double) -> Void
    var onSkip: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("今天先照顧自己，再開始也可以")
                        .font(.headline)
                    Text("不用很有力氣，先看看今天適合怎樣的步伐。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("今天心情") {
                    Slider(value: $mood, in: 0...1)
                    HStack {
                        Text("低")
                        Spacer()
                        Text("高")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Section("今天動機") {
                    Slider(value: $drive, in: 0...1)
                    HStack {
                        Text("只想先活著")
                        Spacer()
                        Text("想好好前進")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Section("昨天 Bingo 難度") {
                    Slider(value: $difficulty, in: 0...1)
                    HStack {
                        Text("太輕鬆")
                        Spacer()
                        Text("太吃力")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("今日狀態")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("略過") { onSkip() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { onSave(mood, drive, difficulty) }
                }
            }
        }
    }
}
