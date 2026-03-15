import Testing
import Foundation
@testable import CaloriesRings

@Suite("HistoryPresenter")
struct HistoryPresenterTests {

    @Test("Group by day with empty entries returns empty")
    @MainActor
    func groupByDayEmpty() {
        let presenter = HistoryPresenter()
        let groups = presenter.groupByDay([])
        #expect(groups.isEmpty)
    }

    @Test("Chart points accumulate correctly")
    @MainActor
    func chartPointsAccumulate() {
        let presenter = HistoryPresenter()
        // Use noon to avoid midnight boundary issues
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let entries = [
            MealEntry(timestamp: noon, mealType: .breakfast, deltaCalories: 300),
            MealEntry(timestamp: noon.addingTimeInterval(3600), mealType: .lunch, deltaCalories: 500)
        ]
        let points = presenter.chartPoints(for: entries, on: noon)
        #expect(points.count == 2)
        #expect(points[0].total == 300)
        #expect(points[1].total == 800)
    }
}
