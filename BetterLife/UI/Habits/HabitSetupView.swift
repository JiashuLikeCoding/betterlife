import SwiftUI

struct HabitSetupView: View {
    @Environment(\.dismiss) private var dismiss

    private let defaultStepsCount = 7

    @State private var habitName: String = ""
    @State private var habitType: HabitType = .focusExecution
    @State private var stage: HabitStage = .starting
    @State private var barrier: MainBarrier = .lowMotivation
    @State private var isCore: Bool = true

    @State private var microSteps: [String] = []
    @State private var starterStep: String = ""
    @State private var didManuallyEditSteps: Bool = false
    @State private var isEditingSteps: Bool = false

    @State private var contextHint: String = "日常最順手的時間"
    @State private var successDefinition: String = "完成第一步就算做到"
    @State private var freeNote: String = ""

    var onSave: (Habit) -> Void

    private func bindingForStep(at index: Int) -> Binding<String> {
        Binding(
            get: { microSteps.indices.contains(index) ? microSteps[index] : "" },
            set: { newValue in
                didManuallyEditSteps = true
                if microSteps.indices.contains(index) {
                    microSteps[index] = newValue
                }
            }
        )
    }

    private func deleteSteps(at offsets: IndexSet) {
        didManuallyEditSteps = true
        microSteps.remove(atOffsets: offsets)
        if microSteps.isEmpty {
            starterStep = ""
        } else if !microSteps.contains(starterStep) {
            starterStep = microSteps.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
    }

    private func regenerateSteps(force: Bool) {
        let name = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if !force && didManuallyEditSteps { return }

        let suggestions = AIStepSuggester.suggestMicroSteps(habitName: name)
        microSteps = Array(suggestions.prefix(defaultStepsCount))
        starterStep = microSteps.first ?? ""
        if force == true {
            didManuallyEditSteps = false
        }
    }

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

                Section("小儀式（30 秒內）") {
                    Text("先選一個你做得到的第一步。這些小步驟也會成為 Bingo 的習慣任務來源。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if microSteps.isEmpty {
                        Text("先輸入習慣名稱，我會幫你起草幾個小步驟；你可以刪改到順手為止。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("AI 幫我起草小步驟") {
                        regenerateSteps(force: true)
                    }

                    // Tap-to-select (no keyboard)
                    let cleaned = microSteps
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    ForEach(cleaned, id: \.self) { step in
                        Button {
                            starterStep = step
                        } label: {
                            HStack(spacing: 12) {
                                Text(step)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if starterStep.trimmingCharacters(in: .whitespacesAndNewlines) == step {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        Divider()
                    }

                    Button(isEditingSteps ? "完成編輯" : "編輯小步驟") {
                        isEditingSteps.toggle()
                    }

                    if isEditingSteps {
                        ForEach(microSteps.indices, id: \.self) { idx in
                            TextField("小步驟 \(idx + 1)", text: bindingForStep(at: idx))
                                .textInputAutocapitalization(.never)
                        }
                        .onDelete(perform: deleteSteps)

                        Button("＋新增一條") {
                            didManuallyEditSteps = true
                            microSteps.append("")
                        }
                    }

                    TextField("起手式（可自行修改）", text: $starterStep)
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
                        let cleanedSteps = microSteps
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        let starter = starterStep.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalStarter = starter.isEmpty ? (cleanedSteps.first ?? name) : starter

                        var finalSteps = cleanedSteps
                        if finalSteps.isEmpty {
                            finalSteps = AIStepSuggester.suggestMicroSteps(habitName: name)
                        }
                        if !finalSteps.contains(finalStarter) {
                            finalSteps.insert(finalStarter, at: 0)
                        }

                        let habit = Habit(
                            habitName: name,
                            habitType: habitType,
                            stage: stage,
                            mainBarrier: barrier,
                            isCore: isCore,
                            microSteps: finalSteps,
                            starterStep: finalStarter,
                            contextHint: contextHint.trimmingCharacters(in: .whitespacesAndNewlines),
                            successDefinition: successDefinition.trimmingCharacters(in: .whitespacesAndNewlines),
                            freeNote: freeNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(habit)
                        dismiss()
                    }
                }
            }
            .onAppear {
                regenerateSteps(force: false)
            }
            .onChange(of: habitName) { _ in
                regenerateSteps(force: false)
            }
        }
    }
}
