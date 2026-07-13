import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var presenter = OnboardingPresenter()

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    Stepper("Age: \(presenter.age)", value: $presenter.age, in: 16...90)
                    Picker("Sex", selection: $presenter.sex) {
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                    }
                    Stepper("Height: \(presenter.heightCm) cm", value: $presenter.heightCm, in: 130...220)
                    Stepper("Weight: \(presenter.weightKg) kg", value: $presenter.weightKg, in: 40...200)
                }
                Section("Activity level") {
                    Picker("", selection: $presenter.activityIndex) {
                        Text("Mostly sitting").tag(0)
                        Text("Some walking each day").tag(1)
                        Text("Regular workouts 2–3x/week").tag(2)
                        Text("Very active most days").tag(3)
                    }
                    .pickerStyle(.inline)
                }
                Section("Goal") {
                    Picker("", selection: $presenter.goalIndex) {
                        Text("Lose weight gently").tag(0)
                        Text("Maintain weight").tag(1)
                        Text("Gain weight / build up").tag(2)
                    }
                    .pickerStyle(.inline)
                }
                Section("Suggested plan") {
                    Text("Suggested daily goal: \(presenter.suggestedDailyGoal) kcal").font(.headline)
                    Slider(
                        value: Binding(
                            get: { Double(presenter.suggestedDailyGoal) },
                            set: { presenter.suggestedDailyGoal = Int($0) }
                        ),
                        in: 1200...3200,
                        step: 50
                    ) { Text("Daily calories") }
                }
                Section {
                    Button("Finish onboarding") { presenter.completeOnboarding(context: context) }
                        .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("About you")
            .onAppear { presenter.recalculateSuggestion() }
            .onChange(of: presenter.age) { presenter.recalculateSuggestion() }
            .onChange(of: presenter.sex) { presenter.recalculateSuggestion() }
            .onChange(of: presenter.heightCm) { presenter.recalculateSuggestion() }
            .onChange(of: presenter.weightKg) { presenter.recalculateSuggestion() }
            .onChange(of: presenter.activityIndex) { presenter.recalculateSuggestion() }
            .onChange(of: presenter.goalIndex) { presenter.recalculateSuggestion() }
            .alert("Error", isPresented: $presenter.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(presenter.errorMessage)
            }
        }
    }
}
