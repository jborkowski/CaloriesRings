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
        return save(entry: entry, context: context)
    }

    private func save(entry: MealEntry, context: ModelContext) -> Bool {
        context.insert(entry)
        do {
            try context.save()
            WidgetCenter.shared.reloadTimelines(ofKind: "CaloriesRingsWidget")
            let nutrition = HealthKitNutrition(entry: entry)
            Task { try? await HealthKitManager.shared.save(nutrition) }
            return true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showingError = true
            return false
        }
    }
}
