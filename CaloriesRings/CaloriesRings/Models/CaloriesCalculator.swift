//
//  CaloriesCalculator.swift
//  CaloriesRings
//
//  Business logic for calorie calculations
//  Extracted from views for testability and reusability
//

import Foundation

/// Encapsulates all calorie-related calculations using evidence-based formulas
struct CaloriesCalculator {
    
    // MARK: - Constants
    
    /// Minimum safe daily calorie intake (prevents malnutrition)
    static let minimumDailyCalories = 1200
    
    /// Maximum daily calorie intake (reasonable upper limit)
    static let maximumDailyCalories = 3200
    
    /// Calorie adjustment for weight loss goal (0.25kg/week loss)
    static let weightLossDeficit = 300
    
    /// Calorie adjustment for weight gain goal (0.25kg/week gain)
    static let weightGainSurplus = 300
    
    // MARK: - Types
    
    enum BiologicalSex: Sendable {
        case male
        case female
        
        init?(string: String) {
            switch string.lowercased() {
            case "male": self = .male
            case "female": self = .female
            default: return nil
            }
        }
    }
    
    enum ActivityLevel: Sendable {
        case sedentary      // Mostly sitting, little exercise
        case light          // Light exercise 1-3 days/week
        case moderate       // Moderate exercise 3-5 days/week
        case veryActive     // Hard exercise 6-7 days/week
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .veryActive: return 1.725
            }
        }
        
        init(index: Int) {
            switch index {
            case 0: self = .sedentary
            case 1: self = .light
            case 2: self = .moderate
            default: self = .veryActive
            }
        }
    }
    
    enum WeightGoal: Sendable {
        case lose       // Gentle weight loss
        case maintain   // Maintain current weight
        case gain       // Controlled weight gain
        
        var calorieAdjustment: Int {
            switch self {
            case .lose: return -CaloriesCalculator.weightLossDeficit
            case .maintain: return 0
            case .gain: return CaloriesCalculator.weightGainSurplus
            }
        }
        
        init(index: Int) {
            switch index {
            case 0: self = .lose
            case 1: self = .maintain
            default: self = .gain
            }
        }
    }
    
    struct UserMetrics: Sendable {
        let age: Int
        let sex: BiologicalSex
        let heightCm: Int
        let weightKg: Int
        
        /// Validates that all metrics are within safe and reasonable ranges
        func isValid() -> Bool {
            return age >= 16 && age <= 90 &&
                   heightCm >= 130 && heightCm <= 220 &&
                   weightKg >= 40 && weightKg <= 200
        }
    }
    
    struct CalorieGoal: Sendable {
        let dailyTotal: Int
        let bmr: Double
        let tdee: Int
        let adjustedForGoal: Int
    }
    
    // MARK: - BMR Calculation
    
    /// Calculates Basal Metabolic Rate using the Mifflin-St Jeor equation
    ///
    /// This is the most accurate formula for estimating BMR without body composition data.
    /// It accounts for differences in lean body mass between sexes.
    ///
    /// - Male formula: BMR = 10W + 6.25H - 5A + 5
    /// - Female formula: BMR = 10W + 6.25H - 5A - 161
    ///
    /// Where: W = weight (kg), H = height (cm), A = age (years)
    ///
    /// - Parameter metrics: User's physical characteristics
    /// - Returns: Basal Metabolic Rate in kcal/day
    static func calculateBMR(metrics: UserMetrics) -> Double {
        let sexConstant: Double = (metrics.sex == .male) ? 5.0 : -161.0
        
        let bmr = 10.0 * Double(metrics.weightKg) +
                  6.25 * Double(metrics.heightCm) -
                  5.0 * Double(metrics.age) +
                  sexConstant
        
        return bmr
    }
    
    // MARK: - TDEE Calculation
    
    /// Calculates Total Daily Energy Expenditure
    ///
    /// TDEE represents the total calories burned in a day including:
    /// - BMR (basal metabolic rate)
    /// - Physical activity
    /// - Thermic effect of food
    /// - Non-exercise activity thermogenesis (NEAT)
    ///
    /// - Parameters:
    ///   - bmr: Basal metabolic rate
    ///   - activityLevel: User's typical activity level
    /// - Returns: Total daily energy expenditure in kcal/day
    static func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Int {
        return Int(bmr * activityLevel.multiplier)
    }
    
    // MARK: - Complete Goal Calculation
    
    /// Calculates a complete calorie goal with all adjustments
    ///
    /// This is the main entry point for calculating user's daily calorie target.
    /// It combines BMR, activity level, and goal adjustments with safety bounds.
    ///
    /// - Parameters:
    ///   - metrics: User's physical characteristics
    ///   - activityLevel: User's typical activity level
    ///   - goal: User's weight management goal
    /// - Returns: Complete calorie goal breakdown, or nil if metrics invalid
    static func calculateDailyGoal(
        metrics: UserMetrics,
        activityLevel: ActivityLevel,
        goal: WeightGoal
    ) -> CalorieGoal? {
        guard metrics.isValid() else { return nil }
        
        let bmr = calculateBMR(metrics: metrics)
        let tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel)
        let adjusted = tdee + goal.calorieAdjustment
        let clamped = clampToSafeRange(adjusted)
        
        return CalorieGoal(
            dailyTotal: clamped,
            bmr: bmr,
            tdee: tdee,
            adjustedForGoal: adjusted
        )
    }
    
    // MARK: - Safety Bounds
    
    /// Clamps calorie goal to safe range [1200, 3200]
    ///
    /// - 1200 minimum: Prevents malnutrition and metabolic slowdown
    /// - 3200 maximum: Reasonable upper limit for most people
    ///
    /// - Parameter calories: Calculated calorie goal
    /// - Returns: Clamped value within safe range
    static func clampToSafeRange(_ calories: Int) -> Int {
        return max(minimumDailyCalories, min(calories, maximumDailyCalories))
    }
    
    // MARK: - Meal Distribution
    
    /// Default meal distribution percentages
    ///
    /// Based on common dietary patterns:
    /// - Larger breakfast for energy and metabolism
    /// - Moderate lunch to maintain energy
    /// - Lighter dinner to avoid late-day surplus
    /// - Snacks tracked but not allocated by default
    struct MealDistribution: Sendable {
        static let breakfastPercent = 0.4   // 40%
        static let lunchPercent = 0.35      // 35%
        static let dinnerPercent = 0.25     // 25%
        
        let breakfast: Int
        let lunch: Int
        let dinner: Int
        let snack: Int
        
        /// Creates meal targets from daily goal
        ///
        /// Note: Dinner is calculated as remainder to ensure exact sum
        /// This handles rounding errors from Int conversion
        ///
        /// - Parameter dailyGoal: Total daily calorie target
        init(dailyGoal: Int) {
            self.breakfast = Int(Double(dailyGoal) * Self.breakfastPercent)
            self.lunch = Int(Double(dailyGoal) * Self.lunchPercent)
            self.dinner = dailyGoal - self.breakfast - self.lunch
            self.snack = 0  // User can add snacks but no default target
        }
        
    }
}

// MARK: - Macro Goals

extension CaloriesCalculator {
    struct MacroGoals: Sendable {
        let proteinGrams: Double
        let carbsGrams: Double
        let fatGrams: Double
    }

    static func macroGoals(dailyCalorieGoal: Int) -> MacroGoals {
        let kcal = Double(dailyCalorieGoal)
        return MacroGoals(
            proteinGrams: kcal * 0.30 / 4,
            carbsGrams:   kcal * 0.40 / 4,
            fatGrams:     kcal * 0.30 / 9
        )
    }
}

// MARK: - Zone Calculator

/// Calculates color zones for calorie progress indicators
struct ZoneCalculator {
    
    enum Zone: Sendable {
        case green      // On target or under
        case yellow     // Slightly over target
        case red        // Significantly over target
        
        var description: String {
            switch self {
            case .green: return "On target"
            case .yellow: return "Slightly over"
            case .red: return "Over target"
            }
        }
    }
    
    /// Default threshold for green zone (100% of target)
    static let defaultGreenUpperPercent = 100
    
    /// Default threshold for yellow zone (130% of target)
    static let defaultYellowUpperPercent = 130
    
    /// Calculates which zone a calorie total falls into
    ///
    /// - Parameters:
    ///   - consumed: Calories consumed
    ///   - target: Target calories
    ///   - greenUpper: Upper percent for green zone (default: 100)
    ///   - yellowUpper: Upper percent for yellow zone (default: 130)
    /// - Returns: Zone classification
    static func calculateZone(
        consumed: Int,
        target: Int,
        greenUpper: Int = defaultGreenUpperPercent,
        yellowUpper: Int = defaultYellowUpperPercent
    ) -> Zone {
        guard target > 0 else { return .green }
        
        let percent = Double(consumed) / Double(target) * 100.0
        
        if percent <= Double(greenUpper) {
            return .green
        } else if percent <= Double(yellowUpper) {
            return .yellow
        } else {
            return .red
        }
    }
    
    /// Calculates progress percentage (0.0 to 1.5+)
    ///
    /// Used for rendering progress rings. Capped at 1.5 for visual clarity.
    ///
    /// - Parameters:
    ///   - consumed: Calories consumed
    ///   - target: Target calories
    /// - Returns: Progress ratio (0.0 = empty, 1.0 = complete, 1.5 = way over)
    static func calculateProgress(consumed: Int, target: Int) -> Double {
        guard target > 0 else { return 0.0 }
        return min(Double(consumed) / Double(target), 1.5)
    }
}

