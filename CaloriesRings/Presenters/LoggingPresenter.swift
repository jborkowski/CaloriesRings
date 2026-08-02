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

    let caloriePresets = [100, 200, 300, 400]
    let mealPresets = MealPreset.defaults

    func save(delta: Int, context: ModelContext) -> Bool {
        let entry = MealEntry(mealType: selectedMeal, deltaCalories: delta)
        return save(entry: entry, context: context)
    }

    func save(preset: MealPreset, context: ModelContext) -> Bool {
        let entry = MealEntry(
            mealType: selectedMeal,
            deltaCalories: preset.calories,
            note: preset.name,
            proteinGrams: preset.proteinGrams,
            carbsGrams: preset.carbsGrams,
            fatGrams: preset.fatGrams
        )
        return save(entry: entry, context: context)
    }

    func save(savedPreset: SavedMealPreset, context: ModelContext) -> Bool {
        savedPreset.lastUsedAt = .now
        let entry = MealEntry(
            mealType: selectedMeal,
            deltaCalories: savedPreset.calories,
            note: savedPreset.name,
            proteinGrams: savedPreset.proteinGrams,
            carbsGrams: savedPreset.carbsGrams,
            fatGrams: savedPreset.fatGrams
        )
        return save(entry: entry, context: context)
    }

    func delete(savedPreset: SavedMealPreset, context: ModelContext) {
        context.delete(savedPreset)
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to delete preset: \(error.localizedDescription)"
            showingError = true
        }
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
