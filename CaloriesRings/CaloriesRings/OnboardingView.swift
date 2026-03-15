import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var age: Int = 30
    @State private var sex: String = "male"
    @State private var heightCm: Int = 175
    @State private var weightKg: Int = 90
    @State private var activityIndex: Int = 1 // 0..3
    @State private var goalIndex: Int = 0 // 0 lose, 1 maintain, 2 gain

    @State private var suggestedDailyGoal: Int = 1800
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    Stepper("Age: \(age)", value: $age, in: 16...90)

                    Picker("Sex", selection: $sex) {
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                    }

                    Stepper("Height: \(heightCm) cm", value: $heightCm, in: 130...220)
                    Stepper("Weight: \(weightKg) kg", value: $weightKg, in: 40...200)
                }

                Section("Activity level") {
                    Picker("", selection: $activityIndex) {
                        Text("Mostly sitting").tag(0)
                        Text("Some walking each day").tag(1)
                        Text("Regular workouts 2–3x/week").tag(2)
                        Text("Very active most days").tag(3)
                    }
                    .pickerStyle(.inline)
                }

                Section("Goal") {
                    Picker("", selection: $goalIndex) {
                        Text("Lose weight gently").tag(0)
                        Text("Maintain weight").tag(1)
                        Text("Gain weight / build up").tag(2)
                    }
                    .pickerStyle(.inline)
                }

                Section("Suggested plan") {
                    Text("Suggested daily goal: \(suggestedDailyGoal) kcal")
                        .font(.headline)

                    Slider(
                        value: Binding(
                            get: { Double(suggestedDailyGoal) },
                            set: { suggestedDailyGoal = Int($0) }
                        ),
                        in: 1200...3200,
                        step: 50
                    ) {
                        Text("Daily calories")
                    }
                }

                Section {
                    Button("Finish onboarding") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("About you")
            .onAppear {
                recalculateSuggestion()
            }
            .onChange(of: age) { recalculateSuggestion() }
            .onChange(of: sex) { recalculateSuggestion() }
            .onChange(of: heightCm) { recalculateSuggestion() }
            .onChange(of: weightKg) { recalculateSuggestion() }
            .onChange(of: activityIndex) { recalculateSuggestion() }
            .onChange(of: goalIndex) { recalculateSuggestion() }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    /// Recalculates suggested calorie goal using CalorieCalculator
    private func recalculateSuggestion() {
        guard let biologicalSex = CalorieCalculator.BiologicalSex(string: sex) else {
            return
        }
        
        let metrics = CalorieCalculator.UserMetrics(
            age: age,
            sex: biologicalSex,
            heightCm: heightCm,
            weightKg: weightKg
        )
        
        let activityLevel = CalorieCalculator.ActivityLevel(index: activityIndex)
        let weightGoal = CalorieCalculator.WeightGoal(index: goalIndex)
        
        guard let calorieGoal = CalorieCalculator.calculateDailyGoal(
            metrics: metrics,
            activityLevel: activityLevel,
            goal: weightGoal
        ) else {
            // This shouldn't happen with steppers, but handle gracefully
            return
        }
        
        suggestedDailyGoal = calorieGoal.dailyTotal
    }

    /// Completes onboarding and creates user profile
    private func completeOnboarding() {
        // Use CalorieCalculator for meal distribution
        let distribution = CalorieCalculator.MealDistribution(dailyGoal: suggestedDailyGoal)
        
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
