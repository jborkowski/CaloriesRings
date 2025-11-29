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
            .onChange(of: age) { _ in recalculateSuggestion() }
            .onChange(of: sex) { _ in recalculateSuggestion() }
            .onChange(of: heightCm) { _ in recalculateSuggestion() }
            .onChange(of: weightKg) { _ in recalculateSuggestion() }
            .onChange(of: activityIndex) { _ in recalculateSuggestion() }
            .onChange(of: goalIndex) { _ in recalculateSuggestion() }
        }
    }

    private func recalculateSuggestion() {
        // Very simple Mifflin-St Jeor style estimate
        let s = (sex == "male") ? 5.0 : -161.0
        let bmr = 10.0 * Double(weightKg) + 6.25 * Double(heightCm) - 5.0 * Double(age) + s

        let activityMultiplier: Double
        switch activityIndex {
        case 0: activityMultiplier = 1.2
        case 1: activityMultiplier = 1.375
        case 2: activityMultiplier = 1.55
        default: activityMultiplier = 1.725
        }

        var maintenance = Int(bmr * activityMultiplier)

        switch goalIndex {
        case 0: // lose gently
            maintenance -= 300
        case 2: // gain
            maintenance += 300
        default:
            break
        }

        suggestedDailyGoal = max(1200, min(maintenance, 3200))
    }

    private func completeOnboarding() {
        // Simple split: 40% / 35% / 25%
        let b = Int(Double(suggestedDailyGoal) * 0.4)
        let l = Int(Double(suggestedDailyGoal) * 0.35)
        let d = suggestedDailyGoal - b - l

        let profile = UserProfile(
            dailyCalorieGoal: suggestedDailyGoal,
            breakfastTarget: b,
            lunchTarget: l,
            dinnerTarget: d,
            snackTarget: 0,
            onboardingCompletedAt: Date()
        )
        context.insert(profile)
        try? context.save()
    }
}
