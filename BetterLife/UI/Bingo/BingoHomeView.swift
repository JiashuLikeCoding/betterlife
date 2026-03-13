import SwiftUI

struct BingoHomeView: View {
    @StateObject private var vm = BingoHomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.habits.isEmpty {
                    EmptyHabitsView {
                        vm.showHabitSetup = true
                    }
                } else {
                    VStack(spacing: 12) {
                        HabitPickerRow(
                            habits: vm.habits,
                            selectedHabitId: $vm.selectedHabitId
                        )

                        if let header = vm.headerCopy {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(header.title)
                                    .font(.headline)
                                Text(header.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }

                        if let board = vm.board {
                            BingoBoardView(board: board, onToggle: { index in
                                vm.toggle(index: index)
                            })
                            .padding(.horizontal)
                        } else {
                            ProgressView()
                                .task { await vm.loadOrGenerateBoard() }
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
            .navigationTitle("自愛花園")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.showHabitSetup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新增習慣")
                }
            }
            .sheet(isPresented: $vm.showCheckIn) {
                DailyCheckInView(
                    mood: vm.pendingMood,
                    drive: vm.pendingDrive,
                    difficulty: vm.pendingYesterdayDifficulty,
                    onSave: { mood, drive, diff in
                        vm.saveCheckIn(mood: mood, drive: drive, yesterdayDifficulty: diff)
                    },
                    onSkip: {
                        vm.skipCheckIn()
                    }
                )
            }
            .sheet(isPresented: $vm.showHabitSetup) {
                HabitSetupView { habit in
                    vm.addHabit(habit)
                }
            }
            .task {
                await vm.bootstrap()
            }
        }
    }
}

private struct EmptyHabitsView: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("先種下一顆小種子")
                .font(.title2)
                .fontWeight(.semibold)

            Text("從一個想照顧的習慣開始，花園就會有方向。")
                .foregroundStyle(.secondary)

            Button("建立第一個習慣") {
                onCreate()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct HabitPickerRow: View {
    let habits: [Habit]
    @Binding var selectedHabitId: UUID

    var body: some View {
        HStack {
            Text("核心習慣")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Picker("習慣", selection: $selectedHabitId) {
                ForEach(habits) { habit in
                    Text(habit.habitName).tag(habit.id)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
