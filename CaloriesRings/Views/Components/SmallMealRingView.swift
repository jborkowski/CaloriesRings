import SwiftUI

struct SmallMealRingView: View {
    let meal: MealType
    let totals: TodayPresenter.MealTotals
    let profile: UserProfile
    let presenter: TodayPresenter

    private var consumed: Int { totals.calories(for: meal) }
    private var target: Int { presenter.mealTarget(for: meal, profile: profile) }

    var body: some View {
        let progress = presenter.mealProgress(consumed: consumed, target: target)
        let zone = presenter.mealZone(consumed: consumed, target: target)

        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(Color.gray.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color(for: zone).opacity(0.8), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 60, height: 60)
            Text(meal.shortLabel).font(.caption2)
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
