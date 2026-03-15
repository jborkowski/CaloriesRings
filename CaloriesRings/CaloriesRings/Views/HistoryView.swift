import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var entries: [MealEntry]
    @State private var presenter = HistoryPresenter()

    let profile: UserProfile

    var body: some View {
        let days = presenter.groupByDay(entries)

        NavigationStack {
            List(days) { day in
                NavigationLink {
                    DayDetailView(date: day.id, entries: day.entries, profile: profile)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(day.id, style: .date)
                            Text("\(day.total) kcal").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}
