//
//  MealEntry.swift
//  CaloriesRings
//
//  Created by Jonatan Borkowski on 29/11/2025.
//

import Foundation
import SwiftData
enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}

@Model
final class MealEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var mealTypeRaw: String
    var deltaCalories: Int
    var note: String?
    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .breakfast }
        set { mealTypeRaw = newValue.rawValue }
    }
    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        mealType: MealType,
        deltaCalories: Int,
        note: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mealTypeRaw = mealType.rawValue
        self.deltaCalories = deltaCalories
        self.note = note
    }
}
