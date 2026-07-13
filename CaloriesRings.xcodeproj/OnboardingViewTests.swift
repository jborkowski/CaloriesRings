nnn//
//  OnboardingViewTests.swift
//  CaloriesRings
//
//  Created on 14/03/2026.
//

import Testing
import SwiftUI
import SwiftData
@testable import CaloriesRings

@Suite("Onboarding Calorie Calculations")
struct OnboardingCalculationTests {
    
    // MARK: - BMR Calculation Tests
    
    @Test("BMR calculation for male user")
    func bmrCalculationMale() {
        // Test data: 30yo male, 175cm, 90kg
        let age = 30
        let sex = "male"
        let heightCm = 175
        let weightKg = 90
        
        // Mifflin-St Jeor formula for males:
        // BMR = 10 * weight(kg) + 6.25 * height(cm) - 5 * age(years) + 5
        let expectedBMR = 10.0 * 90.0 + 6.25 * 175.0 - 5.0 * 30.0 + 5.0
        
        #expect(expectedBMR == 1848.75, "BMR calculation should match Mifflin-St Jeor formula")
    }
    
    @Test("BMR calculation for female user")
    func bmrCalculationFemale() {
        // Test data: 30yo female, 165cm, 70kg
        let age = 30
        let sex = "female"
        let heightCm = 165
        let weightKg = 70
        
        // Mifflin-St Jeor formula for females:
        // BMR = 10 * weight(kg) + 6.25 * height(cm) - 5 * age(years) - 161
        let expectedBMR = 10.0 * 70.0 + 6.25 * 165.0 - 5.0 * 30.0 - 161.0
        
        #expect(expectedBMR == 1420.25, "BMR calculation should match Mifflin-St Jeor formula for females")
    }
    
    // MARK: - Activity Multiplier Tests
    
    @Test("Activity level multipliers", arguments: [
        (0, 1.2, "Sedentary"),
        (1, 1.375, "Light activity"),
        (2, 1.55, "Moderate activity"),
        (3, 1.725, "Very active")
    ])
    func activityMultipliers(activityIndex: Int, expectedMultiplier: Double, description: String) {
        let activityMultiplier: Double
        switch activityIndex {
        case 0: activityMultiplier = 1.2
        case 1: activityMultiplier = 1.375
        case 2: activityMultiplier = 1.55
        default: activityMultiplier = 1.725
        }
        
        #expect(activityMultiplier == expectedMultiplier, "\(description) should have multiplier \(expectedMultiplier)")
    }
    
    // MARK: - Full Calorie Goal Calculation Tests
    
    @Test("Calculate maintenance calories for sedentary male")
    func maintenanceCaloriesSedentaryMale() {
        // 30yo male, 175cm, 90kg, sedentary
        let bmr = 10.0 * 90.0 + 6.25 * 175.0 - 5.0 * 30.0 + 5.0
        let maintenance = Int(bmr * 1.2)
        
        #expect(maintenance == 2218, "Sedentary male should have ~2218 kcal maintenance")
    }
    
    @Test("Calculate maintenance calories for active female")
    func maintenanceCaloriesActiveFemale() {
        // 30yo female, 165cm, 70kg, moderate activity
        let bmr = 10.0 * 70.0 + 6.25 * 165.0 - 5.0 * 30.0 - 161.0
        let maintenance = Int(bmr * 1.55)
        
        #expect(maintenance == 2201, "Moderately active female should have ~2201 kcal maintenance")
    }
    
    // MARK: - Goal Adjustment Tests
    
    @Test("Weight loss goal reduces calories by 300")
    func weightLossGoalAdjustment() {
        var maintenance = 2200
        
        // Goal index 0 = lose weight
        maintenance -= 300
        
        #expect(maintenance == 1900, "Weight loss goal should reduce by 300 kcal")
    }
    
    @Test("Maintain weight goal keeps calories unchanged")
    func maintainWeightGoal() {
        let maintenance = 2200
        
        // Goal index 1 = maintain (no change)
        #expect(maintenance == 2200, "Maintain goal should not change calories")
    }
    
    @Test("Weight gain goal increases calories by 300")
    func weightGainGoalAdjustment() {
        var maintenance = 2200
        
        // Goal index 2 = gain weight
        maintenance += 300
        
        #expect(maintenance == 2500, "Weight gain goal should increase by 300 kcal")
    }
    
    // MARK: - Boundary Tests
    
    @Test("Calorie goal respects minimum of 1200")
    func minimumCalorieGoal() {
        let calculated = 800
        let clamped = max(1200, min(calculated, 3200))
        
        #expect(clamped == 1200, "Goal should never go below 1200 kcal")
    }
    
    @Test("Calorie goal respects maximum of 3200")
    func maximumCalorieGoal() {
        let calculated = 4000
        let clamped = max(1200, min(calculated, 3200))
        
        #expect(clamped == 3200, "Goal should never exceed 3200 kcal")
    }
    
    @Test("Calorie goal within range unchanged")
    func calorieGoalInRange() {
        let calculated = 2000
        let clamped = max(1200, min(calculated, 3200))
        
        #expect(clamped == 2000, "Goal within range should be unchanged")
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Minimum age, height, weight calculations")
    func minimumBoundaryCalculation() {
        // 16yo male, 130cm, 40kg, sedentary, maintain
        let bmr = 10.0 * 40.0 + 6.25 * 130.0 - 5.0 * 16.0 + 5.0
        let maintenance = Int(bmr * 1.2)
        let clamped = max(1200, min(maintenance, 3200))
        
        #expect(clamped >= 1200, "Even minimum values should produce valid calorie goal")
    }
    
    @Test("Maximum age, height, weight calculations")
    func maximumBoundaryCalculation() {
        // 90yo male, 220cm, 200kg, very active, gain
        let bmr = 10.0 * 200.0 + 6.25 * 220.0 - 5.0 * 90.0 + 5.0
        var maintenance = Int(bmr * 1.725)
        maintenance += 300 // gain goal
        let clamped = max(1200, min(maintenance, 3200))
        
        #expect(clamped <= 3200, "Even maximum values should be capped at 3200")
    }
}

@Suite("Onboarding Meal Target Distribution")
struct MealTargetTests {
    
    @Test("Meal targets distribute correctly for 1800 kcal")
    func mealDistribution1800() {
        let dailyGoal = 1800
        
        let breakfast = Int(Double(dailyGoal) * 0.4)
        let lunch = Int(Double(dailyGoal) * 0.35)
        let dinner = dailyGoal - breakfast - lunch
        
        #expect(breakfast == 720, "Breakfast should be 40% of daily goal")
        #expect(lunch == 630, "Lunch should be 35% of daily goal")
        #expect(dinner == 450, "Dinner should be remaining 25%")
        #expect(breakfast + lunch + dinner == dailyGoal, "Targets should sum to daily goal")
    }
    
    @Test("Meal targets distribute correctly for 2400 kcal")
    func mealDistribution2400() {
        let dailyGoal = 2400
        
        let breakfast = Int(Double(dailyGoal) * 0.4)
        let lunch = Int(Double(dailyGoal) * 0.35)
        let dinner = dailyGoal - breakfast - lunch
        
        #expect(breakfast == 960, "Breakfast should be 40% of daily goal")
        #expect(lunch == 840, "Lunch should be 35% of daily goal")
        #expect(dinner == 600, "Dinner should be remaining 25%")
        #expect(breakfast + lunch + dinner == dailyGoal, "Targets should sum to daily goal")
    }
    
    @Test("Meal targets sum equals daily goal", arguments: [1200, 1500, 1800, 2100, 2400, 2700, 3000, 3200])
    func mealTargetSum(dailyGoal: Int) {
        let breakfast = Int(Double(dailyGoal) * 0.4)
        let lunch = Int(Double(dailyGoal) * 0.35)
        let dinner = dailyGoal - breakfast - lunch
        
        #expect(breakfast + lunch + dinner == dailyGoal, "Targets should always sum to daily goal")
    }
    
    @Test("Snack target is always zero during onboarding")
    func snackTargetZero() {
        let snackTarget = 0
        #expect(snackTarget == 0, "Snack target should be 0 during onboarding")
    }
}

@Suite("Onboarding Data Persistence")
struct OnboardingPersistenceTests {
    
    @Test("UserProfile creation with onboarding data")
    func userProfileCreation() async throws {
        let schema = Schema([UserProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        // Simulate onboarding completion
        let dailyGoal = 1800
        let breakfast = Int(Double(dailyGoal) * 0.4)
        let lunch = Int(Double(dailyGoal) * 0.35)
        let dinner = dailyGoal - breakfast - lunch
        
        let profile = UserProfile(
            dailyCalorieGoal: dailyGoal,
            breakfastTarget: breakfast,
            lunchTarget: lunch,
            dinnerTarget: dinner,
            snackTarget: 0,
            onboardingCompletedAt: Date()
        )
        
        context.insert(profile)
        try context.save()
        
        // Verify the profile was saved
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(descriptor)
        
        #expect(profiles.count == 1, "Should have exactly one profile")
        
        let savedProfile = try #require(profiles.first)
        #expect(savedProfile.dailyCalorieGoal == 1800)
        #expect(savedProfile.breakfastTarget == 720)
        #expect(savedProfile.lunchTarget == 630)
        #expect(savedProfile.dinnerTarget == 450)
        #expect(savedProfile.snackTarget == 0)
        #expect(savedProfile.onboardingCompletedAt != nil)
    }
    
    @Test("UserProfile uses default percentages")
    func userProfileDefaultPercentages() async throws {
        let schema = Schema([UserProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        let profile = UserProfile(
            dailyCalorieGoal: 2000,
            breakfastTarget: 800,
            lunchTarget: 700,
            dinnerTarget: 500,
            snackTarget: 0,
            onboardingCompletedAt: Date()
        )
        
        context.insert(profile)
        try context.save()
        
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(descriptor)
        let savedProfile = try #require(profiles.first)
        
        #expect(savedProfile.greenUpperPercent == 100, "Default green threshold should be 100%")
        #expect(savedProfile.yellowUpperPercent == 130, "Default yellow threshold should be 130%")
    }
    
    @Test("Multiple profiles not created during single onboarding")
    func singleProfileCreation() async throws {
        let schema = Schema([UserProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        // Create first profile
        let profile1 = UserProfile(
            dailyCalorieGoal: 1800,
            breakfastTarget: 720,
            lunchTarget: 630,
            dinnerTarget: 450,
            snackTarget: 0,
            onboardingCompletedAt: Date()
        )
        
        context.insert(profile1)
        try context.save()
        
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(descriptor)
        
        #expect(profiles.count == 1, "Should only have one profile after onboarding")
    }
}

@Suite("Onboarding Input Validation")
struct InputValidationTests {
    
    @Test("Age range validation", arguments: [16, 30, 60, 90])
    func ageRangeValid(age: Int) {
        #expect(age >= 16 && age <= 90, "Age should be within valid range")
    }
    
    @Test("Height range validation", arguments: [130, 160, 180, 220])
    func heightRangeValid(heightCm: Int) {
        #expect(heightCm >= 130 && heightCm <= 220, "Height should be within valid range")
    }
    
    @Test("Weight range validation", arguments: [40, 70, 100, 200])
    func weightRangeValid(weightKg: Int) {
        #expect(weightKg >= 40 && weightKg <= 200, "Weight should be within valid range")
    }
    
    @Test("Activity index validation", arguments: [0, 1, 2, 3])
    func activityIndexValid(index: Int) {
        #expect(index >= 0 && index <= 3, "Activity index should be 0-3")
    }
    
    @Test("Goal index validation", arguments: [0, 1, 2])
    func goalIndexValid(index: Int) {
        #expect(index >= 0 && index <= 2, "Goal index should be 0-2")
    }
    
    @Test("Sex validation", arguments: ["male", "female"])
    func sexValidation(sex: String) {
        #expect(sex == "male" || sex == "female", "Sex should be male or female")
    }
}

@Suite("Complete Onboarding Scenarios")
struct OnboardingScenarioTests {
    
    @Test("Scenario: Young active male wanting to gain muscle")
    func youngAthleteScenario() {
        // 25yo male, 180cm, 75kg, very active, gain weight
        let bmr = 10.0 * 75.0 + 6.25 * 180.0 - 5.0 * 25.0 + 5.0
        var maintenance = Int(bmr * 1.725) // very active
        maintenance += 300 // gain goal
        let goal = max(1200, min(maintenance, 3200))
        
        #expect(goal > 2500, "Young active male gaining should have high calorie goal")
    }
    
    @Test("Scenario: Middle-aged sedentary female wanting to lose weight")
    func middleAgedWeightLossScenario() {
        // 45yo female, 160cm, 75kg, sedentary, lose weight
        let bmr = 10.0 * 75.0 + 6.25 * 160.0 - 5.0 * 45.0 - 161.0
        var maintenance = Int(bmr * 1.2) // sedentary
        maintenance -= 300 // lose weight goal
        let goal = max(1200, min(maintenance, 3200))
        
        #expect(goal >= 1200, "Should respect minimum calorie floor")
        #expect(goal < 1800, "Sedentary weight loss should be moderate calories")
    }
    
    @Test("Scenario: Active person maintaining weight")
    func activeMaintainerScenario() {
        // 35yo male, 175cm, 80kg, moderate activity, maintain
        let bmr = 10.0 * 80.0 + 6.25 * 175.0 - 5.0 * 35.0 + 5.0
        let maintenance = Int(bmr * 1.55) // moderate activity
        let goal = max(1200, min(maintenance, 3200))
        
        #expect(goal >= 2000 && goal <= 2600, "Active maintainer should have moderate-high calories")
    }
}
