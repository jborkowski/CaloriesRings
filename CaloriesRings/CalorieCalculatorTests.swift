//
//  CalorieCalculatorTests.swift
//  CaloriesRings
//
//  Created on 15/03/2026.
//

import Testing
@testable import CaloriesRings

@Suite("Calorie Calculator - BMR Calculations")
struct BMRCalculationTests {
    
    @Test("BMR calculation for adult male")
    func bmrMale() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 175,
            weightKg: 90
        )
        
        let bmr = CalorieCalculator.calculateBMR(metrics: metrics)
        
        // 10 * 90 + 6.25 * 175 - 5 * 30 + 5 = 1848.75
        #expect(bmr == 1848.75, "BMR should match Mifflin-St Jeor formula for males")
    }
    
    @Test("BMR calculation for adult female")
    func bmrFemale() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 30,
            sex: .female,
            heightCm: 165,
            weightKg: 70
        )
        
        let bmr = CalorieCalculator.calculateBMR(metrics: metrics)
        
        // 10 * 70 + 6.25 * 165 - 5 * 30 - 161 = 1420.25
        #expect(bmr == 1420.25, "BMR should match Mifflin-St Jeor formula for females")
    }
    
    @Test("BMR increases with weight")
    func bmrWeightRelationship() {
        let lighter = CalorieCalculator.UserMetrics(age: 30, sex: .male, heightCm: 175, weightKg: 70)
        let heavier = CalorieCalculator.UserMetrics(age: 30, sex: .male, heightCm: 175, weightKg: 90)
        
        let bmrLight = CalorieCalculator.calculateBMR(metrics: lighter)
        let bmrHeavy = CalorieCalculator.calculateBMR(metrics: heavier)
        
        #expect(bmrHeavy > bmrLight, "Heavier person should have higher BMR")
    }
    
    @Test("BMR decreases with age")
    func bmrAgeRelationship() {
        let younger = CalorieCalculator.UserMetrics(age: 25, sex: .male, heightCm: 175, weightKg: 80)
        let older = CalorieCalculator.UserMetrics(age: 50, sex: .male, heightCm: 175, weightKg: 80)
        
        let bmrYoung = CalorieCalculator.calculateBMR(metrics: younger)
        let bmrOld = CalorieCalculator.calculateBMR(metrics: older)
        
        #expect(bmrYoung > bmrOld, "Younger person should have higher BMR")
    }
}

@Suite("Calorie Calculator - Activity Levels")
struct ActivityLevelTests {
    
    @Test("Activity level multipliers are correct")
    func activityMultipliers() {
        #expect(CalorieCalculator.ActivityLevel.sedentary.multiplier == 1.2)
        #expect(CalorieCalculator.ActivityLevel.light.multiplier == 1.375)
        #expect(CalorieCalculator.ActivityLevel.moderate.multiplier == 1.55)
        #expect(CalorieCalculator.ActivityLevel.veryActive.multiplier == 1.725)
    }
    
    @Test("Activity level from index", arguments: [
        (0, CalorieCalculator.ActivityLevel.sedentary),
        (1, CalorieCalculator.ActivityLevel.light),
        (2, CalorieCalculator.ActivityLevel.moderate),
        (3, CalorieCalculator.ActivityLevel.veryActive)
    ])
    func activityFromIndex(index: Int, expected: CalorieCalculator.ActivityLevel) {
        let activity = CalorieCalculator.ActivityLevel(index: index)
        #expect(activity == expected)
    }
    
    @Test("TDEE calculation with sedentary activity")
    func tdeeSedentary() {
        let bmr = 1800.0
        let tdee = CalorieCalculator.calculateTDEE(bmr: bmr, activityLevel: .sedentary)
        
        #expect(tdee == 2160, "TDEE = BMR * 1.2 = 2160")
    }
    
    @Test("TDEE calculation with very active")
    func tdeeVeryActive() {
        let bmr = 2000.0
        let tdee = CalorieCalculator.calculateTDEE(bmr: bmr, activityLevel: .veryActive)
        
        #expect(tdee == 3450, "TDEE = BMR * 1.725 = 3450")
    }
}

@Suite("Calorie Calculator - Weight Goals")
struct WeightGoalTests {
    
    @Test("Weight goal adjustments")
    func goalAdjustments() {
        #expect(CalorieCalculator.WeightGoal.lose.calorieAdjustment == -300)
        #expect(CalorieCalculator.WeightGoal.maintain.calorieAdjustment == 0)
        #expect(CalorieCalculator.WeightGoal.gain.calorieAdjustment == 300)
    }
    
    @Test("Weight goal from index", arguments: [
        (0, CalorieCalculator.WeightGoal.lose),
        (1, CalorieCalculator.WeightGoal.maintain),
        (2, CalorieCalculator.WeightGoal.gain)
    ])
    func goalFromIndex(index: Int, expected: CalorieCalculator.WeightGoal) {
        let goal = CalorieCalculator.WeightGoal(index: index)
        #expect(goal == expected)
    }
}

@Suite("Calorie Calculator - Complete Goal Calculation")
struct CompleteGoalCalculationTests {
    
    @Test("Complete calculation: sedentary male losing weight")
    func sedentaryMaleLoseWeight() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 175,
            weightKg: 90
        )
        
        let goal = CalorieCalculator.calculateDailyGoal(
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
    func activeFemaleMatain() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 35,
            sex: .female,
            heightCm: 165,
            weightKg: 65
        )
        
        let goal = CalorieCalculator.calculateDailyGoal(
            metrics: metrics,
            activityLevel: .moderate,
            goal: .maintain
        )
        
        let result = try #require(goal)
        
        // BMR = 10*65 + 6.25*165 - 5*35 - 161 = 1295.25
        // TDEE = 1295.25 * 1.55 = 2007.6375 → 2007
        // Adjusted = 2007 + 0 = 2007
        #expect(result.bmr == 1295.25)
        #expect(result.tdee == 2007)
        #expect(result.adjustedForGoal == 2007)
        #expect(result.dailyTotal == 2007)
    }
    
    @Test("Complete calculation: very active male gaining")
    func veryActiveMaleGain() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 25,
            sex: .male,
            heightCm: 180,
            weightKg: 75
        )
        
        let goal = CalorieCalculator.calculateDailyGoal(
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

@Suite("Calorie Calculator - Safety Bounds")
struct SafetyBoundsTests {
    
    @Test("Minimum calorie floor is enforced")
    func minimumFloor() {
        let clamped = CalorieCalculator.clampToSafeRange(800)
        #expect(clamped == 1200, "Should never go below 1200")
    }
    
    @Test("Maximum calorie ceiling is enforced")
    func maximumCeiling() {
        let clamped = CalorieCalculator.clampToSafeRange(4000)
        #expect(clamped == 3200, "Should never exceed 3200")
    }
    
    @Test("Values in range are unchanged")
    func inRangeUnchanged() {
        let clamped = CalorieCalculator.clampToSafeRange(2000)
        #expect(clamped == 2000, "Should not modify values in valid range")
    }
    
    @Test("Edge case: exactly at minimum")
    func exactlyAtMinimum() {
        let clamped = CalorieCalculator.clampToSafeRange(1200)
        #expect(clamped == 1200)
    }
    
    @Test("Edge case: exactly at maximum")
    func exactlyAtMaximum() {
        let clamped = CalorieCalculator.clampToSafeRange(3200)
        #expect(clamped == 3200)
    }
}

@Suite("Calorie Calculator - Input Validation")
struct InputValidationTests {
    
    @Test("Valid metrics pass validation")
    func validMetrics() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 175,
            weightKg: 80
        )
        
        #expect(metrics.isValid(), "Normal metrics should be valid")
    }
    
    @Test("Age below minimum is invalid")
    func ageTooLow() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 15,
            sex: .male,
            heightCm: 175,
            weightKg: 80
        )
        
        #expect(!metrics.isValid(), "Age below 16 should be invalid")
    }
    
    @Test("Age above maximum is invalid")
    func ageTooHigh() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 91,
            sex: .male,
            heightCm: 175,
            weightKg: 80
        )
        
        #expect(!metrics.isValid(), "Age above 90 should be invalid")
    }
    
    @Test("Height below minimum is invalid")
    func heightTooLow() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 129,
            weightKg: 80
        )
        
        #expect(!metrics.isValid(), "Height below 130 should be invalid")
    }
    
    @Test("Weight below minimum is invalid")
    func weightTooLow() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 30,
            sex: .male,
            heightCm: 175,
            weightKg: 39
        )
        
        #expect(!metrics.isValid(), "Weight below 40 should be invalid")
    }
    
    @Test("Invalid metrics return nil goal")
    func invalidMetricsReturnNil() {
        let metrics = CalorieCalculator.UserMetrics(
            age: 10,  // Invalid
            sex: .male,
            heightCm: 175,
            weightKg: 80
        )
        
        let goal = CalorieCalculator.calculateDailyGoal(
            metrics: metrics,
            activityLevel: .moderate,
            goal: .maintain
        )
        
        #expect(goal == nil, "Invalid metrics should return nil")
    }
}

@Suite("Calorie Calculator - Meal Distribution")
struct MealDistributionTests {
    
    @Test("Meal distribution for 1800 kcal")
    func distribution1800() {
        let dist = CalorieCalculator.MealDistribution(dailyGoal: 1800)
        
        #expect(dist.breakfast == 720, "40% of 1800")
        #expect(dist.lunch == 630, "35% of 1800")
        #expect(dist.dinner == 450, "Remaining 25%")
        #expect(dist.snack == 0, "Snacks not allocated by default")
    }
    
    @Test("Meal distribution for 2400 kcal")
    func distribution2400() {
        let dist = CalorieCalculator.MealDistribution(dailyGoal: 2400)
        
        #expect(dist.breakfast == 960, "40% of 2400")
        #expect(dist.lunch == 840, "35% of 2400")
        #expect(dist.dinner == 600, "Remaining 25%")
        #expect(dist.snack == 0)
    }
    
    @Test("Meal targets always sum to daily goal", arguments: [
        1200, 1500, 1800, 2000, 2200, 2400, 2600, 3000, 3200
    ])
    func sumEqualsDailyGoal(dailyGoal: Int) {
        let dist = CalorieCalculator.MealDistribution(dailyGoal: dailyGoal)
        let sum = dist.breakfast + dist.lunch + dist.dinner + dist.snack
        
        #expect(sum == dailyGoal, "Meal targets should always sum to daily goal")
    }
    
    @Test("Distribution validation")
    func distributionIsValid() {
        let dist = CalorieCalculator.MealDistribution(dailyGoal: 2000)
        #expect(dist.isValid, "Distribution should be valid")
    }
}

@Suite("Zone Calculator - Zone Classification")
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
        let zone = ZoneCalculator.calculateZone(
            consumed: 550,
            target: 500,
            greenUpper: 110,
            yellowUpper: 140
        )
        #expect(zone == .green, "110% should be green with custom threshold")
    }
    
    @Test("Zero target defaults to green")
    func zeroTargetGreen() {
        let zone = ZoneCalculator.calculateZone(consumed: 100, target: 0)
        #expect(zone == .green, "Zero target should default to green")
    }
}

@Suite("Zone Calculator - Progress Calculation")
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

@Suite("Calorie Calculator - BiologicalSex Parsing")
struct BiologicalSexParsingTests {
    
    @Test("Parse 'male' string")
    func parseMale() {
        let sex = CalorieCalculator.BiologicalSex(string: "male")
        #expect(sex == .male)
    }
    
    @Test("Parse 'female' string")
    func parseFemale() {
        let sex = CalorieCalculator.BiologicalSex(string: "female")
        #expect(sex == .female)
    }
    
    @Test("Parse case-insensitive")
    func parseCaseInsensitive() {
        #expect(CalorieCalculator.BiologicalSex(string: "MALE") == .male)
        #expect(CalorieCalculator.BiologicalSex(string: "Female") == .female)
    }
    
    @Test("Invalid string returns nil")
    func parseInvalid() {
        let sex = CalorieCalculator.BiologicalSex(string: "other")
        #expect(sex == nil, "Invalid sex string should return nil")
    }
}
