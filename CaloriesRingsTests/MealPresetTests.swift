import SwiftData
import Testing
@testable import CaloriesRings

@Suite("Meal presets")
struct MealPresetTests {
    @Test("Built-in presets include oatmeal and two eggs with macros")
    @MainActor
    func builtInPresets() {
        let oatmeal = MealPreset.defaults.first { $0.id == "oatmeal-50g" }
        let eggs = MealPreset.defaults.first { $0.id == "two-large-eggs" }

        #expect(oatmeal?.name == "Oatmeal")
        #expect(oatmeal?.calories == 190)
        #expect(oatmeal?.carbsGrams == 33.8)
        #expect(eggs?.name == "2 Eggs")
        #expect(eggs?.calories == 156)
        #expect(eggs?.proteinGrams == 12.6)
    }

    @Test("Logging a preset stores its name and full nutrition")
    @MainActor
    func loggingPreset() throws {
        let schema = Schema([MealEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let presenter = LoggingPresenter()
        presenter.selectedMeal = .breakfast

        let preset = try #require(MealPreset.defaults.first { $0.id == "two-large-eggs" })
        #expect(presenter.save(preset: preset, context: context))

        let entries = try context.fetch(FetchDescriptor<MealEntry>())
        let entry = try #require(entries.first)
        #expect(entries.count == 1)
        #expect(entry.mealType == .breakfast)
        #expect(entry.note == "2 Eggs")
        #expect(entry.deltaCalories == 156)
        #expect(entry.proteinGrams == 12.6)
        #expect(entry.carbsGrams == 1.1)
        #expect(entry.fatGrams == 10.6)
    }

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
