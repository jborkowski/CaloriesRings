//
//  UserProfile.swift
//  CaloriesRings
//
//  Created by Jonatan Borkowski on 29/11/2025.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var dailyCalorieGoal: Int
    var breakfastTarget: Int
    var lunchTarget: Int
    var dinnerTarget: Int
    var snackTarget: Int
    var greenUpperPercent: Int
    var yellowUpperPercent: Int
    var onboardingCompletedAt: Date?
    init(
        id: UUID = UUID(),
        dailyCalorieGoal: Int,
        breakfastTarget: Int,
        lunchTarget: Int,
        dinnerTarget: Int,
        snackTarget: Int,
        greenUpperPercent: Int = 100,
        yellowUpperPercent: Int = 130,
        onboardingCompletedAt: Date? = nil
    ) {
        self.id = id
        self.dailyCalorieGoal = dailyCalorieGoal
        self.breakfastTarget = breakfastTarget
        self.lunchTarget = lunchTarget
        self.dinnerTarget = dinnerTarget
        self.snackTarget = snackTarget
        self.greenUpperPercent = greenUpperPercent
        self.yellowUpperPercent = yellowUpperPercent
        self.onboardingCompletedAt = onboardingCompletedAt
    }
}
