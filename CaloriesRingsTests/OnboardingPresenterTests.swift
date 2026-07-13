import Testing
@testable import CaloriesRings

@Suite("OnboardingPresenter")
struct OnboardingPresenterTests {

    @Test("Recalculate with default values produces reasonable goal")
    @MainActor
    func recalculateDefault() {
        let presenter = OnboardingPresenter()
        presenter.recalculateSuggestion()
        #expect(presenter.suggestedDailyGoal >= 1200)
        #expect(presenter.suggestedDailyGoal <= 3200)
    }

    @Test("Male goal is higher than female goal at same metrics")
    @MainActor
    func recalculateSexChange() {
        let presenter = OnboardingPresenter()
        presenter.sex = "male"
        presenter.recalculateSuggestion()
        let maleGoal = presenter.suggestedDailyGoal

        presenter.sex = "female"
        presenter.recalculateSuggestion()
        let femaleGoal = presenter.suggestedDailyGoal

        #expect(maleGoal > femaleGoal)
    }
}
