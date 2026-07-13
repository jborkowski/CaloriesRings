import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class OnboardingPresenter {
    var age: Int = 30
    var sex: String = "male"
    var heightCm: Int = 175
    var weightKg: Int = 90
    var activityIndex: Int = 1
    var goalIndex: Int = 0
    var suggestedDailyGoal: Int = 1800
    var showingError = false
    var errorMessage = ""

    func recalculateSuggestion() {
        guard let biologicalSex = CaloriesCalculator.BiologicalSex(string: sex) else { return }
        let metrics = CaloriesCalculator.UserMetrics(age: age, sex: biologicalSex, heightCm: heightCm, weightKg: weightKg)
        let activityLevel = CaloriesCalculator.ActivityLevel(index: activityIndex)
        let weightGoal = CaloriesCalculator.WeightGoal(index: goalIndex)
        guard let goal = CaloriesCalculator.calculateDailyGoal(metrics: metrics, activityLevel: activityLevel, goal: weightGoal) else { return }
        suggestedDailyGoal = goal.dailyTotal
    }

    func completeOnboarding(context: ModelContext) {
        let distribution = CaloriesCalculator.MealDistribution(dailyGoal: suggestedDailyGoal)
        let profile = UserProfile(
            dailyCalorieGoal: suggestedDailyGoal,
            breakfastTarget: distribution.breakfast,
            lunchTarget: distribution.lunch,
            dinnerTarget: distribution.dinner,
            snackTarget: distribution.snack,
            onboardingCompletedAt: Date()
        )
        context.insert(profile)
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to save your profile. Please try again.\n\nError: \(error.localizedDescription)"
            showingError = true
        }
    }
}
