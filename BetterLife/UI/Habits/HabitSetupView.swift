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

    // AI Coach
    @State private var coachProfile: CoachProfile? = nil
    @State private var coachOtherText: [String: String] = [:]
    @State private var coachSelected: [String: Set<String>] = [:]

    @State private var contextHint: String = "日常最順手的時間"
    @State private var successDefinition: String = "完成第一步就算做到"
    @State private var freeNote: String = ""

    var onSave: (Habit) -> Void

    // MARK: - AI Coach

    private func coachBinding(_ key: String) -> Binding<Set<String>> {
        Binding(
            get: { coachSelected[key] ?? [] },
            set: { coachSelected[key] = $0 }
        )
    }

    private func otherBinding(_ key: String) -> Binding<String> {
        Binding(
            get: { coachOtherText[key] ?? "" },
            set: { coachOtherText[key] = $0 }
        )
    }

    @ViewBuilder
    private func coachSection(kind: CoachHabitKind) -> some View {
        switch kind {
        case .exercise:
            CoachQuestionViews.ChipsRow(
                title: "你想做咩類型？（可多選）",
                options: ["徒手", "伸展", "瑜伽", "跑步", "健身房", "走路"],
                allowsMultiple: true,
                selection: coachBinding("exercise.type"),
                otherText: otherBinding("exercise.type_other"),
                otherPlaceholder: "其他類型…"
            )

            CoachQuestionViews.ChipsRow(
                title: "最小版本多長？",
                options: ["30秒", "2分鐘", "5分鐘"],
                allowsMultiple: false,
                selection: coachBinding("exercise.dose"),
                otherText: otherBinding("exercise.dose_other"),
                otherPlaceholder: "其他時間…"
            )

            CoachQuestionViews.ChipsRow(
                title: "最大阻力係邊個？",
                options: ["太累", "沒時間", "不想出門", "不知道做什麼", "容易中斷"],
                allowsMultiple: false,
                selection: coachBinding("exercise.barrier"),
                otherText: otherBinding("exercise.barrier_other"),
                otherPlaceholder: "其他阻力…"
            )

        case .sleep:
            CoachQuestionViews.ChipsRow(
                title: "你想幾點上床/熄燈？",
                options: ["10:00", "10:30", "11:00", "11:30", "12:00"],
                allowsMultiple: false,
                selection: coachBinding("sleep.bedtime"),
                otherText: otherBinding("sleep.bedtime_other"),
                otherPlaceholder: "其他時間…"
            )

            CoachQuestionViews.ChipsRow(
                title: "最大阻力係邊個？",
                options: ["手機", "腦袋停唔到", "做唔完嘢", "環境/室友"],
                allowsMultiple: false,
                selection: coachBinding("sleep.barrier"),
                otherText: otherBinding("sleep.barrier_other"),
                otherPlaceholder: "其他阻力…"
            )

            CoachQuestionViews.ChipsRow(
                title: "你想用咩收工儀式？",
                options: ["把手機放遠離床", "調暗燈光", "熱水澡", "寫一句明天最重要的事"],
                allowsMultiple: false,
                selection: coachBinding("sleep.ritual"),
                otherText: otherBinding("sleep.ritual_other"),
                otherPlaceholder: "其他儀式…"
            )

        case .wake:
            CoachQuestionViews.ChipsRow(
                title: "你想幾點起身？",
                options: ["6:30", "7:00", "7:30", "8:00", "8:30"],
                allowsMultiple: false,
                selection: coachBinding("wake.time"),
                otherText: otherBinding("wake.time_other"),
                otherPlaceholder: "其他時間…"
            )

            CoachQuestionViews.ChipsRow(
                title: "你起唔到身最常係因為？",
                options: ["太攰", "很痛苦", "手機", "覺得冇必要"],
                allowsMultiple: false,
                selection: coachBinding("wake.barrier"),
                otherText: otherBinding("wake.barrier_other"),
                otherPlaceholder: "其他原因…"
            )

            CoachQuestionViews.ChipsRow(
                title: "起身後第一件事係咩？",
                options: ["坐起身10秒", "開窗呼吸一口", "喝三口水", "去洗手間"],
                allowsMultiple: false,
                selection: coachBinding("wake.first"),
                otherText: otherBinding("wake.first_other"),
                otherPlaceholder: "其他第一步…"
            )

        case .reading:
            CoachQuestionViews.ChipsRow(
                title: "你想讀咩類型？",
                options: ["小說", "非虛構", "學習/教材", "漫畫"],
                allowsMultiple: false,
                selection: coachBinding("reading.genre"),
                otherText: otherBinding("reading.genre_other"),
                otherPlaceholder: "其他類型…"
            )

            CoachQuestionViews.ChipsRow(
                title: "你想用頁數定時間？（擇一）",
                options: ["1頁", "1段", "5分鐘", "10分鐘"],
                allowsMultiple: false,
                selection: coachBinding("reading.dose"),
                otherText: otherBinding("reading.dose_other"),
                otherPlaceholder: "其他…"
            )

            CoachQuestionViews.ChipsRow(
                title: "最大阻力係？",
                options: ["拿唔起書", "容易分心", "不知道讀什麼", "讀兩頁就想停"],
                allowsMultiple: false,
                selection: coachBinding("reading.barrier"),
                otherText: otherBinding("reading.barrier_other"),
                otherPlaceholder: "其他阻力…"
            )
        }
    }

    private func buildCoachProfile(kind: CoachHabitKind) -> CoachProfile {
        var answers: [String: [String]] = [:]
        for (k, v) in coachSelected {
            answers[k] = Array(v)
        }
        return CoachProfile(kind: kind, answers: answers, otherText: coachOtherText)
    }

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

        let suggestions = AIStepSuggester.suggestMicroSteps(habitName: name, coachProfile: coachProfile)
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
                }

                if let kind = CoachQuestionViews.inferKind(from: habitName) {
                    Section("AI 導師（可跳過）") {
                        Text("先問三個小問題，讓小步驟更貼近你。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        coachSection(kind: kind)

                        Button("用這些答案起草小步驟") {
                            coachProfile = buildCoachProfile(kind: kind)
                            didManuallyEditSteps = false
                            regenerateSteps(force: true)
                        }
                    }
                }

                Section("這個習慣") {
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
                            finalSteps = AIStepSuggester.suggestMicroSteps(habitName: name, coachProfile: coachProfile)
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
                            coachProfile: coachProfile,
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
