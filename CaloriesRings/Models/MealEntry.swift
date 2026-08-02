//
//  MealEntry.swift
//  CaloriesRings
//
//  Created by Jonatan Borkowski on 29/11/2025.
//

import Foundation
import SwiftData
enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast, lunch, dinner, snack

    var label: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    var shortLabel: String {
        switch self {
        case .breakfast: return "B"
        case .lunch: return "L"
        case .dinner: return "D"
        case .snack: return "S"
        }
    }
}

enum SwiftDataStoreProtection {
    static func prepareStoreDirectory(at directoryURL: URL) throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        try setCompleteProtection(at: directoryURL)
    }

    static func applyProtection(toStoreAt storeURL: URL) {
        let protectedURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in protectedURLs where FileManager.default.fileExists(atPath: url.path) {
            try? setCompleteProtection(at: url)
        }
    }

    private static func setCompleteProtection(at url: URL) throws {
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }
}

@Model
final class SavedMealPreset {
    @Attribute(.unique) var id: UUID
    var name: String
    var portionDescription: String
    var symbol: String
    var calories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double
    var mealTypeRaw: String
    var createdAt: Date
    var lastUsedAt: Date?

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .breakfast }
        set { mealTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        portionDescription: String,
        symbol: String = "fork.knife",
        calories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double,
        mealType: MealType,
        createdAt: Date = .now,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.portionDescription = portionDescription
        self.symbol = symbol
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.mealTypeRaw = mealType.rawValue
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

@Model
final class MealEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var mealTypeRaw: String
    var deltaCalories: Int
    var note: String?
    var proteinGrams: Double = 0.0
    var carbsGrams: Double = 0.0
    var fatGrams: Double = 0.0
    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .breakfast }
        set { mealTypeRaw = newValue.rawValue }
    }
    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        mealType: MealType,
        deltaCalories: Int,
        note: String? = nil,
        proteinGrams: Double = 0.0,
        carbsGrams: Double = 0.0,
        fatGrams: Double = 0.0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mealTypeRaw = mealType.rawValue
        self.deltaCalories = deltaCalories
        self.note = note
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
    }
}
