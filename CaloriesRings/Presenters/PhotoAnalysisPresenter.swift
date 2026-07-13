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
    var showingAPIKeyAlert = false
    var apiKeyInput = ""

    func analyze(image: UIImage) {
        state = .analyzing
        Task {
            do {
                let estimate = try await GLMVisionClient.shared.analyzeFood(image: image)
                state = .result(estimate)
            } catch GLMError.missingAPIKey {
                showingAPIKeyAlert = true
                state = .idle
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func saveAPIKey() {
        KeychainClient.save(apiKeyInput)
        apiKeyInput = ""
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
