import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class TodayPresenter {
    var activeMeal: MealType = .breakfast
    var showingLogSheet = false

    struct MealTotals {
        let breakfast: Int
        let lunch: Int
        let dinner: Int
        let snack: Int
        var total: Int { breakfast + lunch + dinner + snack }

        func calories(for meal: MealType) -> Int {
            switch meal {
            case .breakfast: return breakfast
            case .lunch: return lunch
            case .dinner: return dinner
            case .snack: return snack
            }
        }
    }

    func currentMealByTime() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }

    func todayTotals(from entries: [MealEntry]) -> MealTotals {
        let calendar = Calendar.current
        let todayEntries = entries.filter { calendar.isDateInToday($0.timestamp) }

        func total(for type: MealType) -> Int {
            todayEntries.filter { $0.mealType == type }.reduce(0) { $0 + $1.deltaCalories }
        }

        return MealTotals(
            breakfast: total(for: .breakfast),
            lunch: total(for: .lunch),
            dinner: total(for: .dinner),
            snack: total(for: .snack)
        )
    }

    func dailyZone(total: Int, goal: Int, greenUpper: Int, yellowUpper: Int) -> ZoneCalculator.Zone {
        ZoneCalculator.calculateZone(consumed: total, target: goal, greenUpper: greenUpper, yellowUpper: yellowUpper)
    }

    func mealTarget(for meal: MealType, profile: UserProfile) -> Int {
        switch meal {
        case .breakfast: return profile.breakfastTarget
        case .lunch: return profile.lunchTarget
        case .dinner: return profile.dinnerTarget
        case .snack: return profile.snackTarget
        }
    }

    func mealZone(consumed: Int, target: Int) -> ZoneCalculator.Zone {
        ZoneCalculator.calculateZone(consumed: consumed, target: target)
    }

    func mealProgress(consumed: Int, target: Int) -> Double {
        ZoneCalculator.calculateProgress(consumed: consumed, target: target)
    }

    struct MacroTotals {
        let proteinGrams: Double
        let carbsGrams: Double
        let fatGrams: Double
    }

    func macroTotals(from entries: [MealEntry]) -> MacroTotals {
        let today = entries.filter { Calendar.current.isDateInToday($0.timestamp) }
        return MacroTotals(
            proteinGrams: today.reduce(0) { $0 + $1.proteinGrams },
            carbsGrams:   today.reduce(0) { $0 + $1.carbsGrams },
            fatGrams:     today.reduce(0) { $0 + $1.fatGrams }
        )
    }
}
