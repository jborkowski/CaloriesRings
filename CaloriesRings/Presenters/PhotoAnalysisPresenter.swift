import Foundation
import UIKit
import SwiftData
import WidgetKit
import Observation

enum PhotoAnalysisState {
    case idle
    case analyzing
    case result(MacroEstimate)
    case error(String)
}

@Observable @MainActor
final class PhotoAnalysisPresenter {
    var state: PhotoAnalysisState = .idle
    var selectedMeal: MealType = .breakfast

    func analyze(image: UIImage) {
        state = .analyzing
        Task {
            do {
                let estimate = try await FoundationModelsVisionClient.shared.analyzeFood(image: image)
                state = .result(estimate)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func savePreset(estimate: MacroEstimate, context: ModelContext) -> Bool {
        let preset = SavedMealPreset(
            name: estimate.foodName,
            portionDescription: estimate.servingSize,
            calories: estimate.calories,
            proteinGrams: estimate.proteinG,
            carbsGrams: estimate.carbsG,
            fatGrams: estimate.fatG,
            mealType: selectedMeal
        )
        context.insert(preset)
        do {
            try context.save()
            return true
        } catch {
            state = .error("Preset save failed: \(error.localizedDescription)")
            return false
        }
    }

    func accept(estimate: MacroEstimate, context: ModelContext) -> Bool {
        let entry = MealEntry(
            mealType: selectedMeal,
            deltaCalories: estimate.calories,
            note: estimate.foodName,
            proteinGrams: estimate.proteinG,
            carbsGrams: estimate.carbsG,
            fatGrams: estimate.fatG
        )
        context.insert(entry)
        do {
            try context.save()
            WidgetCenter.shared.reloadTimelines(ofKind: "CaloriesRingsWidget")
            let nutrition = HealthKitNutrition(entry: entry)
            Task { try? await HealthKitManager.shared.save(nutrition) }
            return true
        } catch {
            state = .error("Save failed: \(error.localizedDescription)")
            return false
        }
    }

    func reset() { state = .idle }
}
