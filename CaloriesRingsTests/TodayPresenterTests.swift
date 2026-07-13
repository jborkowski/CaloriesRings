import Testing
@testable import CaloriesRings

@Suite("TodayPresenter")
struct TodayPresenterTests {

    @Test("Current meal by time returns a valid meal type")
    @MainActor
    func currentMealByTime() {
        let presenter = TodayPresenter()
        let meal = presenter.currentMealByTime()
        #expect(MealType.allCases.contains(meal))
    }

    @Test("Today totals with empty entries returns zeros")
    @MainActor
    func todayTotalsEmpty() {
        let presenter = TodayPresenter()
        let totals = presenter.todayTotals(from: [])
        #expect(totals.total == 0)
        #expect(totals.breakfast == 0)
    }

    @Test("Meal zone under target is green")
    @MainActor
    func mealZoneGreen() {
        let presenter = TodayPresenter()
        let zone = presenter.mealZone(consumed: 400, target: 500)
        #expect(zone == .green)
    }

    @Test("Meal zone over 100% but under 130% is yellow")
    @MainActor
    func mealZoneYellow() {
        let presenter = TodayPresenter()
        let zone = presenter.mealZone(consumed: 600, target: 500)
        #expect(zone == .yellow)
    }

    @Test("Meal progress capped at 1.5")
    @MainActor
    func progressCapped() {
        let presenter = TodayPresenter()
        let progress = presenter.mealProgress(consumed: 1000, target: 500)
        #expect(progress == 1.5)
    }

    @Test("Macro totals sums today's entries")
    @MainActor
    func macroTotals_sums_todays_entries() {
        let entries = [
            MealEntry(mealType: .lunch, deltaCalories: 400, proteinGrams: 30, carbsGrams: 50, fatGrams: 10),
            MealEntry(mealType: .dinner, deltaCalories: 600, proteinGrams: 45, carbsGrams: 70, fatGrams: 20)
        ]
        let totals = TodayPresenter().macroTotals(from: entries)
        #expect(totals.proteinGrams == 75)
        #expect(totals.carbsGrams == 120)
        #expect(totals.fatGrams == 30)
    }
}
