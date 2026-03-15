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
}
