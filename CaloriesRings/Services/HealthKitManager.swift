import Foundation
import HealthKit

enum HealthKitAuthorizationState: Equatable, Sendable {
    case unavailable
    case notDetermined
    case denied
    case partiallyAuthorized
    case authorized
}

enum HealthKitSyncError: LocalizedError, Sendable {
    case healthDataUnavailable
    case authorizationRequired
    case noNutritionToSave

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Apple Health data is not available on this device."
        case .authorizationRequired:
            return "CaloriesRings does not have permission to save nutrition data to Apple Health."
        case .noNutritionToSave:
            return "This entry does not contain positive nutrition values to save."
        }
    }
}

/// A Sendable snapshot of a meal. SwiftData models stay on the main actor while
/// this value crosses to the HealthKit actor.
struct HealthKitNutrition: Equatable, Sendable {
    let id: UUID
    let date: Date
    let foodName: String
    let calories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double

    @MainActor
    init(entry: MealEntry) {
        id = entry.id
        date = entry.timestamp
        foodName = entry.note ?? entry.mealType.label
        calories = entry.deltaCalories
        proteinGrams = entry.proteinGrams
        carbsGrams = entry.carbsGrams
        fatGrams = entry.fatGrams
    }
}

actor HealthKitManager {
    static let shared = HealthKitManager()

    private let store: HKHealthStore

    private let energyType = HKQuantityType(.dietaryEnergyConsumed)
    private let proteinType = HKQuantityType(.dietaryProtein)
    private let carbohydratesType = HKQuantityType(.dietaryCarbohydrates)
    private let fatType = HKQuantityType(.dietaryFatTotal)

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    private var writeTypes: Set<HKSampleType> {
        [energyType, proteinType, carbohydratesType, fatType]
    }

    func authorizationState() -> HealthKitAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else { return .unavailable }

        let statuses = writeTypes.map { store.authorizationStatus(for: $0) }
        if statuses.allSatisfy({ $0 == .sharingAuthorized }) {
            return .authorized
        }
        if statuses.allSatisfy({ $0 == .notDetermined }) {
            return .notDetermined
        }
        if statuses.allSatisfy({ $0 != .sharingAuthorized }) {
            return .denied
        }
        return .partiallyAuthorized
    }

    @discardableResult
    func requestAuthorization() async throws -> HealthKitAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitSyncError.healthDataUnavailable
        }

        try await store.requestAuthorization(toShare: writeTypes, read: [])
        return authorizationState()
    }

    /// Saves the nutrition categories the user has authorized. Stable sync
    /// identifiers make repeated saves of the same meal idempotent.
    func save(_ nutrition: HealthKitNutrition) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitSyncError.healthDataUnavailable
        }

        let samples = authorizedSamples(for: nutrition)
        guard !samples.isEmpty else {
            let containsNutrition = nutrition.calories > 0 ||
                nutrition.proteinGrams > 0 ||
                nutrition.carbsGrams > 0 ||
                nutrition.fatGrams > 0
            throw containsNutrition
                ? HealthKitSyncError.authorizationRequired
                : HealthKitSyncError.noNutritionToSave
        }

        try await store.save(samples)
    }

    private func authorizedSamples(for nutrition: HealthKitNutrition) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []

        appendSample(
            to: &samples,
            type: energyType,
            value: Double(nutrition.calories),
            unit: .kilocalorie(),
            nutrition: nutrition
        )
        appendSample(
            to: &samples,
            type: proteinType,
            value: nutrition.proteinGrams,
            unit: .gram(),
            nutrition: nutrition
        )
        appendSample(
            to: &samples,
            type: carbohydratesType,
            value: nutrition.carbsGrams,
            unit: .gram(),
            nutrition: nutrition
        )
        appendSample(
            to: &samples,
            type: fatType,
            value: nutrition.fatGrams,
            unit: .gram(),
            nutrition: nutrition
        )

        return samples
    }

    private func appendSample(
        to samples: inout [HKQuantitySample],
        type: HKQuantityType,
        value: Double,
        unit: HKUnit,
        nutrition: HealthKitNutrition
    ) {
        guard value > 0, store.authorizationStatus(for: type) == .sharingAuthorized else { return }

        let metadata: [String: Any] = [
            HKMetadataKeyFoodType: nutrition.foodName,
            HKMetadataKeySyncIdentifier: "me.thebo.CaloriesRings.\(nutrition.id.uuidString).\(type.identifier)",
            HKMetadataKeySyncVersion: 1
        ]

        samples.append(HKQuantitySample(
            type: type,
            quantity: HKQuantity(unit: unit, doubleValue: value),
            start: nutrition.date,
            end: nutrition.date,
            metadata: metadata
        ))
    }
}
