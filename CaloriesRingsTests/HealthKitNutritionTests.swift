import SwiftData
import Testing
@testable import CaloriesRings

@Suite("HealthKit nutrition")
struct HealthKitNutritionTests {
    @Test("HealthKit snapshot keeps the meal identity and nutrition")
    @MainActor
    func healthKitSnapshot() {
        let entry = MealEntry(
            mealType: .breakfast,
            deltaCalories: 190,
            note: "Oatmeal",
            proteinGrams: 6.5,
            carbsGrams: 33.8,
            fatGrams: 3.5
        )

        let nutrition = HealthKitNutrition(entry: entry)
        #expect(nutrition.id == entry.id)
        #expect(nutrition.foodName == "Oatmeal")
        #expect(nutrition.calories == 190)
        #expect(nutrition.proteinGrams == 6.5)
    }
}
