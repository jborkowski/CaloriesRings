import SwiftUI
import Charts

struct DayDetailView: View {
    let date: Date
    let entries: [MealEntry]
    let profile: UserProfile

    @State private var presenter = HistoryPresenter()

    var body: some View {
        let points = presenter.chartPoints(for: entries, on: date)

        VStack(alignment: .leading, spacing: 16) {
            Text(date, style: .date).font(.title2.bold())

            if points.isEmpty {
                Text("No entries for this day").foregroundStyle(.secondary)
            } else {
                Chart(points) { point in
                    LineMark(x: .value("Time", point.time), y: .value("Calories", point.total))
                }
                .frame(height: 220)

                if let last = points.last {
                    Text("Total: \(last.total) / \(profile.dailyCalorieGoal) kcal").font(.headline)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
