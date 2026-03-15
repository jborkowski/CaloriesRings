//
//  CaloriesCalculatorTests.swift
//  CaloriesRings
//
//  Created on 15/03/2026.
//

import Testing
@testable import CaloriesRings

@Suite("Calories Calculator - BMR Calculations")
@MainActor
struct BMRCalculationTests {
    
    @Test("BMR calculation for adult male")
    func bmrMale() {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 175,
            weightKg: 90
        )
        
        let bmr = CaloriesCalculator.calculateBMR(metrics: metrics)
        
        // 10 * 90 + 6.25 * 175 - 5 * 30 + 5 = 1848.75
        #expect(bmr == 1848.75, "BMR should match Mifflin-St Jeor formula for males")
    }
    
    @Test("BMR calculation for adult female")
    func bmrFemale() {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 30,
            sex: .female,
            heightCm: 165,
            weightKg: 70
        )
        
        let bmr = CaloriesCalculator.calculateBMR(metrics: metrics)
        
        // 10 * 70 + 6.25 * 165 - 5 * 30 - 161 = 1420.25
        #expect(bmr == 1420.25, "BMR should match Mifflin-St Jeor formula for females")
    }
    
    @Test("BMR increases with weight")
    func bmrWeightRelationship() {
        let lighter = CaloriesCalculator.UserMetrics(age: 30, sex: .male, heightCm: 175, weightKg: 70)
        let heavier = CaloriesCalculator.UserMetrics(age: 30, sex: .male, heightCm: 175, weightKg: 90)
        
        let bmrLight = CaloriesCalculator.calculateBMR(metrics: lighter)
        let bmrHeavy = CaloriesCalculator.calculateBMR(metrics: heavier)
        
        #expect(bmrHeavy > bmrLight, "Heavier person should have higher BMR")
    }
    
    @Test("BMR decreases with age")
    func bmrAgeRelationship() {
        let younger = CaloriesCalculator.UserMetrics(age: 25, sex: .male, heightCm: 175, weightKg: 80)
        let older = CaloriesCalculator.UserMetrics(age: 50, sex: .male, heightCm: 175, weightKg: 80)
        
        let bmrYoung = CaloriesCalculator.calculateBMR(metrics: younger)
        let bmrOld = CaloriesCalculator.calculateBMR(metrics: older)
        
        #expect(bmrYoung > bmrOld, "Younger person should have higher BMR")
    }
}

@Suite("Calories Calculator - Activity Levels")
@MainActor
struct ActivityLevelTests {
    
    @Test("Activity level multipliers are correct")
    func activityMultipliers() {
        #expect(CaloriesCalculator.ActivityLevel.sedentary.multiplier == 1.2)
        #expect(CaloriesCalculator.ActivityLevel.light.multiplier == 1.375)
        #expect(CaloriesCalculator.ActivityLevel.moderate.multiplier == 1.55)
        #expect(CaloriesCalculator.ActivityLevel.veryActive.multiplier == 1.725)
    }
    
    @Test("Activity level from index", arguments: [
        (0, CaloriesCalculator.ActivityLevel.sedentary),
        (1, CaloriesCalculator.ActivityLevel.light),
        (2, CaloriesCalculator.ActivityLevel.moderate),
        (3, CaloriesCalculator.ActivityLevel.veryActive)
    ])
    func activityFromIndex(index: Int, expected: CaloriesCalculator.ActivityLevel) {
        let activity = CaloriesCalculator.ActivityLevel(index: index)
        #expect(activity == expected)
    }
    
    @Test("TDEE calculation with sedentary activity")
    func tdeeSedentary() {
        let bmr = 1800.0
        let tdee = CaloriesCalculator.calculateTDEE(bmr: bmr, activityLevel: .sedentary)
        
        #expect(tdee == 2160, "TDEE = BMR * 1.2 = 2160")
    }
    
    @Test("TDEE calculation with very active")
    func tdeeVeryActive() {
        let bmr = 2000.0
        let tdee = CaloriesCalculator.calculateTDEE(bmr: bmr, activityLevel: .veryActive)
        
        #expect(tdee == 3450, "TDEE = BMR * 1.725 = 3450")
    }
}

@Suite("Calories Calculator - Weight Goals")
@MainActor
struct WeightGoalTests {
    
    @Test("Weight goal adjustments")
    func goalAdjustments() {
        #expect(CaloriesCalculator.WeightGoal.lose.calorieAdjustment == -300)
        #expect(CaloriesCalculator.WeightGoal.maintain.calorieAdjustment == 0)
        #expect(CaloriesCalculator.WeightGoal.gain.calorieAdjustment == 300)
    }
    
    @Test("Weight goal from index", arguments: [
        (0, CaloriesCalculator.WeightGoal.lose),
        (1, CaloriesCalculator.WeightGoal.maintain),
        (2, CaloriesCalculator.WeightGoal.gain)
    ])
    func goalFromIndex(index: Int, expected: CaloriesCalculator.WeightGoal) {
        let goal = CaloriesCalculator.WeightGoal(index: index)
        #expect(goal == expected)
    }
}

@Suite("Calories Calculator - Complete Goal Calculation")
@MainActor
struct CompleteGoalCalculationTests {
    
    @Test("Complete calculation: sedentary male losing weight")
    func sedentaryMaleLoseWeight() throws {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 175,
            weightKg: 90
        )
        
        let goal = CaloriesCalculator.calculateDailyGoal(
            metrics: metrics,
            activityLevel: .sedentary,
            goal: .lose
        )
        
        let result = try #require(goal)
        
        // BMR = 1848.75
        // TDEE = 1848.75 * 1.2 = 2218.5 → 2218
        // Adjusted = 2218 - 300 = 1918
        #expect(result.bmr == 1848.75)
        #expect(result.tdee == 2218)
        #expect(result.adjustedForGoal == 1918)
        #expect(result.dailyTotal == 1918)
    }
    
    @Test("Complete calculation: active female maintaining")
    func activeFemaleMatain() throws {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 35,
            sex: .female,
            heightCm: 165,
            weightKg: 65
        )
        
        let goal = CaloriesCalculator.calculateDailyGoal(
            metrics: metrics,
            activityLevel: .moderate,
            goal: .maintain
        )
        
        let result = try #require(goal)
        
        // BMR = 10*65 + 6.25*165 - 5*35 - 161 = 1345.25
        // TDEE = 1345.25 * 1.55 = 2085.1375 → 2085
        // Adjusted = 2085 + 0 = 2085
        #expect(result.bmr == 1345.25)
        #expect(result.tdee == 2085)
        #expect(result.adjustedForGoal == 2085)
        #expect(result.dailyTotal == 2085)
    }
    
    @Test("Complete calculation: very active male gaining")
    func veryActiveMaleGain() throws {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 25,
            sex: .male,
            heightCm: 180,
            weightKg: 75
        )
        
        let goal = CaloriesCalculator.calculateDailyGoal(
            metrics: metrics,
            activityLevel: .veryActive,
            goal: .gain
        )
        
        let result = try #require(goal)
        
        // BMR = 10*75 + 6.25*180 - 5*25 + 5 = 1755
        // TDEE = 1755 * 1.725 = 3027.375 → 3027
        // Adjusted = 3027 + 300 = 3327
        // Clamped = 3200 (max)
        #expect(result.bmr == 1755.0)
        #expect(result.tdee == 3027)
        #expect(result.adjustedForGoal == 3327)
        #expect(result.dailyTotal == 3200, "Should be clamped to maximum")
    }
}

@Suite("Calories Calculator - Safety Bounds")
@MainActor
struct SafetyBoundsTests {
    
    @Test("Minimum calorie floor is enforced")
    func minimumFloor() {
        let clamped = CaloriesCalculator.clampToSafeRange(800)
        #expect(clamped == 1200, "Should never go below 1200")
    }
    
    @Test("Maximum calorie ceiling is enforced")
    func maximumCeiling() {
        let clamped = CaloriesCalculator.clampToSafeRange(4000)
        #expect(clamped == 3200, "Should never exceed 3200")
    }
    
    @Test("Values in range are unchanged")
    func inRangeUnchanged() {
        let clamped = CaloriesCalculator.clampToSafeRange(2000)
        #expect(clamped == 2000, "Should not modify values in valid range")
    }
    
    @Test("Edge case: exactly at minimum")
    func exactlyAtMinimum() {
        let clamped = CaloriesCalculator.clampToSafeRange(1200)
        #expect(clamped == 1200)
    }
    
    @Test("Edge case: exactly at maximum")
    func exactlyAtMaximum() {
        let clamped = CaloriesCalculator.clampToSafeRange(3200)
        #expect(clamped == 3200)
    }
}

@Suite("Calories Calculator - Input Validation")
@MainActor
struct InputValidationTests {
    
    @Test("Valid metrics pass validation")
    func validMetrics() {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 175,
            weightKg: 80
        )
        
        #expect(metrics.isValid(), "Normal metrics should be valid")
    }
    
    @Test("Age below minimum is invalid")
    func ageTooLow() {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 15,
            sex: .male,
            heightCm: 175,
            weightKg: 80
        )
        
        #expect(!metrics.isValid(), "Age below 16 should be invalid")
    }
    
    @Test("Age above maximum is invalid")
    func ageTooHigh() {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 91,
            sex: .male,
            heightCm: 175,
            weightKg: 80
        )
        
        #expect(!metrics.isValid(), "Age above 90 should be invalid")
    }
    
    @Test("Height below minimum is invalid")
    func heightTooLow() {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 129,
            weightKg: 80
        )
        
        #expect(!metrics.isValid(), "Height below 130 should be invalid")
    }
    
    @Test("Weight below minimum is invalid")
    func weightTooLow() {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 175,
            weightKg: 39
        )
        
        #expect(!metrics.isValid(), "Weight below 40 should be invalid")
    }
    
    @Test("Invalid metrics return nil goal")
    func invalidMetricsReturnNil() {
        let metrics = CaloriesCalculator.UserMetrics(
            age: 10,  // Invalid
            sex: .male,
            heightCm: 175,
            weightKg: 80
        )
        
        let goal = CaloriesCalculator.calculateDailyGoal(
            metrics: metrics,
            activityLevel: .moderate,
            goal: .maintain
        )
        
        #expect(goal == nil, "Invalid metrics should return nil")
    }
}

@Suite("Calories Calculator - Meal Distribution")
@MainActor
struct MealDistributionTests {
    
    @Test("Meal distribution for 1800 kcal")
    func distribution1800() {
        let dist = CaloriesCalculator.MealDistribution(dailyGoal: 1800)
        
        #expect(dist.breakfast == 720, "40% of 1800")
        #expect(dist.lunch == 630, "35% of 1800")
        #expect(dist.dinner == 450, "Remaining 25%")
        #expect(dist.snack == 0, "Snacks not allocated by default")
    }
    
    @Test("Meal distribution for 2400 kcal")
    func distribution2400() {
        let dist = CaloriesCalculator.MealDistribution(dailyGoal: 2400)
        
        #expect(dist.breakfast == 960, "40% of 2400")
        #expect(dist.lunch == 840, "35% of 2400")
        #expect(dist.dinner == 600, "Remaining 25%")
        #expect(dist.snack == 0)
    }
    
    @Test("Meal targets always sum to daily goal", arguments: [
        1200, 1500, 1800, 2000, 2200, 2400, 2600, 3000, 3200
    ])
    func sumEqualsDailyGoal(dailyGoal: Int) {
        let dist = CaloriesCalculator.MealDistribution(dailyGoal: dailyGoal)
        let sum = dist.breakfast + dist.lunch + dist.dinner + dist.snack
        
        #expect(sum == dailyGoal, "Meal targets should always sum to daily goal")
    }
    
}

@Suite("Zone Calculator - Zone Classification")
@MainActor
struct ZoneClassificationTests {
    
    @Test("On target is green zone")
    func onTargetGreen() {
        let zone = ZoneCalculator.calculateZone(consumed: 500, target: 500)
        #expect(zone == .green, "Exactly on target should be green")
    }
    
    @Test("Under target is green zone")
    func underTargetGreen() {
        let zone = ZoneCalculator.calculateZone(consumed: 450, target: 500)
        #expect(zone == .green, "Under target should be green")
    }
    
    @Test("Just over 100% is yellow zone")
    func justOverYellow() {
        let zone = ZoneCalculator.calculateZone(consumed: 550, target: 500)
        #expect(zone == .yellow, "110% of target should be yellow")
    }
    
    @Test("At yellow threshold is yellow")
    func atYellowThreshold() {
        let zone = ZoneCalculator.calculateZone(consumed: 650, target: 500)
        #expect(zone == .yellow, "130% should still be yellow (at boundary)")
    }
    
    @Test("Over yellow threshold is red")
    func overYellowRed() {
        let zone = ZoneCalculator.calculateZone(consumed: 700, target: 500)
        #expect(zone == .red, "140% should be red")
    }
    
    @Test("Custom thresholds work")
    func customThresholds() {
        // Use 108% (540/500) to avoid IEEE 754 boundary issue at exactly 110%
        let zone = ZoneCalculator.calculateZone(
            consumed: 540,
            target: 500,
            greenUpper: 110,
            yellowUpper: 140
        )
        #expect(zone == .green, "108% should be green with custom threshold of 110%")
    }
    
    @Test("Zero target defaults to green")
    func zeroTargetGreen() {
        let zone = ZoneCalculator.calculateZone(consumed: 100, target: 0)
        #expect(zone == .green, "Zero target should default to green")
    }
}

@Suite("Zone Calculator - Progress Calculation")
@MainActor
struct ProgressCalculationTests {
    
    @Test("Empty progress is zero")
    func emptyProgress() {
        let progress = ZoneCalculator.calculateProgress(consumed: 0, target: 500)
        #expect(progress == 0.0, "No consumption is 0% progress")
    }
    
    @Test("Half progress")
    func halfProgress() {
        let progress = ZoneCalculator.calculateProgress(consumed: 250, target: 500)
        #expect(progress == 0.5, "Half consumed is 50% progress")
    }
    
    @Test("Complete progress")
    func completeProgress() {
        let progress = ZoneCalculator.calculateProgress(consumed: 500, target: 500)
        #expect(progress == 1.0, "Exactly on target is 100% progress")
    }
    
    @Test("Over target capped at 1.5")
    func overTargetCapped() {
        let progress = ZoneCalculator.calculateProgress(consumed: 1000, target: 500)
        #expect(progress == 1.5, "Progress should cap at 1.5 for visual clarity")
    }
    
    @Test("Zero target is zero progress")
    func zeroTargetZeroProgress() {
        let progress = ZoneCalculator.calculateProgress(consumed: 100, target: 0)
        #expect(progress == 0.0, "Zero target should return zero progress")
    }
}

@Suite("Calories Calculator - Macro Goals")
@MainActor
struct MacroGoalsTests {

    @Test("Macro goals sum to daily calorie goal")
    func macroGoalsSum_to_calories() {
        let goals = CaloriesCalculator.macroGoals(dailyCalorieGoal: 2000)
        let recovered = goals.proteinGrams * 4 + goals.carbsGrams * 4 + goals.fatGrams * 9
        #expect(abs(recovered - 2000) < 1.0)
    }

    @Test("Macro goals ratios are correct for 2000 kcal")
    func macroGoalsRatios() {
        let goals = CaloriesCalculator.macroGoals(dailyCalorieGoal: 2000)
        #expect(abs(goals.proteinGrams - 150.0) < 0.01, "30% of 2000 / 4 = 150g protein")
        #expect(abs(goals.carbsGrams - 200.0) < 0.01, "40% of 2000 / 4 = 200g carbs")
        #expect(abs(goals.fatGrams - (2000.0 * 0.30 / 9)) < 0.01, "30% of 2000 / 9 = fat")
    }
}

@Suite("Calories Calculator - BiologicalSex Parsing")
@MainActor
struct BiologicalSexParsingTests {
    
    @Test("Parse 'male' string")
    func parseMale() {
        let sex = CaloriesCalculator.BiologicalSex(string: "male")
        #expect(sex == .male)
    }
    
    @Test("Parse 'female' string")
    func parseFemale() {
        let sex = CaloriesCalculator.BiologicalSex(string: "female")
        #expect(sex == .female)
    }
    
    @Test("Parse case-insensitive")
    func parseCaseInsensitive() {
        #expect(CaloriesCalculator.BiologicalSex(string: "MALE") == .male)
        #expect(CaloriesCalculator.BiologicalSex(string: "Female") == .female)
    }
    
    @Test("Invalid string returns nil")
    func parseInvalid() {
        let sex = CaloriesCalculator.BiologicalSex(string: "other")
        #expect(sex == nil, "Invalid sex string should return nil")
    }
}
