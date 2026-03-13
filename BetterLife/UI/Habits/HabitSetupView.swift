import SwiftUI

struct HabitSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var habitName: String = ""
    @State private var habitType: HabitType = .focusExecution
    @State private var stage: HabitStage = .starting
    @State private var barrier: MainBarrier = .lowMotivation
    @State private var isCore: Bool = true

    @State private var starterStep: String = TaskLibrary.starterSuggestions(for: .focusExecution).first ?? "把手機靜音5分鐘"
    @State private var contextHint: String = "日常最順手的時間"
    @State private var successDefinition: String = "完成第一步就算做到"
    @State private var freeNote: String = ""

    var onSave: (Habit) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("這個習慣") {
                    TextField("例如：閱讀、伸展、寫作", text: $habitName)
                    Picker("類型", selection: $habitType) {
                        ForEach(HabitType.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    Picker("目前程度", selection: $stage) {
                        ForEach(HabitStage.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    Picker("主要阻力", selection: $barrier) {
                        ForEach(MainBarrier.allCases) { b in
                            Text(b.displayName).tag(b)
                        }
                    }
                    Toggle("設為核心習慣", isOn: $isCore)
                }

                Section("起手式（30 秒內）") {
                    Picker("建議", selection: $starterStep) {
                        ForEach(TaskLibrary.starterSuggestions(for: habitType), id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("或自行修改", text: $starterStep)
                        .textInputAutocapitalization(.never)
                }

                Section("可選") {
                    TextField("最順手的時間/情境", text: $contextHint)
                    TextField("怎樣算做到", text: $successDefinition)
                    TextField("你有沒有什麼話想說的？", text: $freeNote, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新增習慣")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let name = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        let habit = Habit(
                            habitName: name,
                            habitType: habitType,
                            stage: stage,
                            mainBarrier: barrier,
                            isCore: isCore,
                            starterStep: starterStep.trimmingCharacters(in: .whitespacesAndNewlines),
                            contextHint: contextHint.trimmingCharacters(in: .whitespacesAndNewlines),
                            successDefinition: successDefinition.trimmingCharacters(in: .whitespacesAndNewlines),
                            freeNote: freeNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(habit)
                        dismiss()
                    }
                }
            }
            .onChange(of: habitType) { newValue in
                let suggestions = TaskLibrary.starterSuggestions(for: newValue)
                if let first = suggestions.first {
                    starterStep = first
                }
            }
        }
    }
}
