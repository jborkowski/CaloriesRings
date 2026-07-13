import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: \MealEntry.timestamp, order: .forward) private var entries: [MealEntry]
    @State private var presenter = TodayPresenter()

    let profile: UserProfile

    var body: some View {
        let totals = presenter.todayTotals(from: entries)
        let dayZone = presenter.dailyZone(
            total: totals.total,
            goal: profile.dailyCalorieGoal,
            greenUpper: profile.greenUpperPercent,
            yellowUpper: profile.yellowUpperPercent
        )

        VStack(spacing: 24) {
            Text("Today").font(.largeTitle.bold())

            ActiveMealRingView(meal: presenter.activeMeal, totals: totals, profile: profile, presenter: presenter)
                .frame(height: 200)

            HStack(spacing: 16) {
                ForEach([MealType.breakfast, .lunch, .dinner], id: \.self) { meal in
                    if meal != presenter.activeMeal {
                        SmallMealRingView(meal: meal, totals: totals, profile: profile, presenter: presenter)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    presenter.activeMeal = meal
                                }
                            }
                    }
                }
            }
            .frame(height: 90)

            HStack(spacing: 8) {
                Circle().fill(color(for: dayZone)).frame(width: 10, height: 10)
                Text("Total: \(totals.total) / \(profile.dailyCalorieGoal) kcal").font(.title3)
            }

            if totals.snack != 0 {
                Text("Snacks: \(totals.snack) kcal").font(.caption).foregroundStyle(.secondary)
            }

            let macros = presenter.macroTotals(from: entries)
            let goals = CaloriesCalculator.macroGoals(dailyCalorieGoal: profile.dailyCalorieGoal)
            HStack(spacing: 24) {
                MacroRingView(label: "Protein", current: macros.proteinGrams, goal: goals.proteinGrams, color: .blue)
                MacroRingView(label: "Carbs",   current: macros.carbsGrams,   goal: goals.carbsGrams,   color: .yellow)
                MacroRingView(label: "Fat",     current: macros.fatGrams,     goal: goals.fatGrams,     color: .red)
            }
            .padding(.top, 8)

            Button(action: { presenter.showingLogSheet = true }) {
                Label("Log \(presenter.activeMeal.label)", systemImage: "plus.circle.fill").font(.title2)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear { presenter.activeMeal = presenter.currentMealByTime() }
        .onChange(of: appState.showLogSheetFromDeepLink) {
            if appState.showLogSheetFromDeepLink {
                presenter.showingLogSheet = true
                appState.showLogSheetFromDeepLink = false
            }
        }
        .sheet(isPresented: $presenter.showingLogSheet) {
            LoggingSheetView(initialMeal: presenter.activeMeal)
                .presentationDetents([.fraction(0.35)])
        }
    }

    private func color(for zone: ZoneCalculator.Zone) -> Color {
        switch zone {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}
