import Foundation

/// A transparent, one-tap meal estimate used by the quick-log screen.
///
/// Portions are part of the preset so users can see what the nutrition estimate
/// represents before adding it.
struct MealPreset: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let portionDescription: String
    let symbol: String
    let calories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double

    static let defaults: [MealPreset] = [
        MealPreset(
            id: "oatmeal-50g",
            name: "Oatmeal",
            portionDescription: "50 g dry oats, with water",
            symbol: "🥣",
            calories: 190,
            proteinGrams: 6.5,
            carbsGrams: 33.8,
            fatGrams: 3.5
        ),
        MealPreset(
            id: "two-large-eggs",
            name: "2 Eggs",
            portionDescription: "2 large eggs",
            symbol: "🥚",
            calories: 156,
            proteinGrams: 12.6,
            carbsGrams: 1.1,
            fatGrams: 10.6
        )
    ]
}
