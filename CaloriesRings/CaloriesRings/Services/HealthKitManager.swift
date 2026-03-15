import Foundation
import HealthKit

actor HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private let writeTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal)
    ]

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: writeTypes, read: [])
    }

    func log(calories: Int, proteinGrams: Double, carbsGrams: Double, fatGrams: Double, at date: Date) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        var samples: [HKQuantitySample] = []

        samples.append(HKQuantitySample(
            type: HKQuantityType(.dietaryEnergyConsumed),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories)),
            start: date, end: date
        ))
        if proteinGrams > 0 {
            samples.append(HKQuantitySample(
                type: HKQuantityType(.dietaryProtein),
                quantity: HKQuantity(unit: .gram(), doubleValue: proteinGrams),
                start: date, end: date
            ))
        }
        if carbsGrams > 0 {
            samples.append(HKQuantitySample(
                type: HKQuantityType(.dietaryCarbohydrates),
                quantity: HKQuantity(unit: .gram(), doubleValue: carbsGrams),
                start: date, end: date
            ))
        }
        if fatGrams > 0 {
            samples.append(HKQuantitySample(
                type: HKQuantityType(.dietaryFatTotal),
                quantity: HKQuantity(unit: .gram(), doubleValue: fatGrams),
                start: date, end: date
            ))
        }
        try? await store.save(samples)
    }
}
