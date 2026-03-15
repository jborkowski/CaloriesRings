import Foundation
import SwiftData
import WidgetKit
import Observation

@Observable
@MainActor
final class LoggingPresenter {
    var selectedMeal: MealType = .breakfast
    var customCalories: String = ""
    var showingError = false
    var errorMessage = ""

    let presets = [100, 200, 300, 400]

    func save(delta: Int, context: ModelContext) -> Bool {
        let entry = MealEntry(mealType: selectedMeal, deltaCalories: delta)
        context.insert(entry)
        do {
            try context.save()
            WidgetCenter.shared.reloadTimelines(ofKind: "CaloriesRingsWidget")
            let (cal, date) = (entry.deltaCalories, entry.timestamp)
            Task { await HealthKitManager.shared.log(calories: cal, proteinGrams: 0, carbsGrams: 0, fatGrams: 0, at: date) }
            return true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showingError = true
            return false
        }
    }
}
