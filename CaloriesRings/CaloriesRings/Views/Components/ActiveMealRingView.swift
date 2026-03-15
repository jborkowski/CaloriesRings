import SwiftUI

struct ActiveMealRingView: View {
    let meal: MealType
    let totals: TodayPresenter.MealTotals
    let profile: UserProfile
    let presenter: TodayPresenter

    private var consumed: Int { totals.calories(for: meal) }
    private var target: Int { presenter.mealTarget(for: meal, profile: profile) }

    var body: some View {
        let progress = presenter.mealProgress(consumed: consumed, target: target)
        let zone = presenter.mealZone(consumed: consumed, target: target)

        VStack(spacing: 12) {
            ZStack {
                Circle().stroke(Color.gray.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color(for: zone), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text("\(consumed)").font(.title)
                    Text("/ \(target) kcal").font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(meal.label).font(.headline)
        }
    }

    private func color(for zone: ZoneCalculator.Zone) -> Color {
        switch zone {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}
