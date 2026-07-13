import Foundation
import Observation

@Observable
@MainActor
final class HistoryPresenter {

    struct DayGroup: Identifiable {
        let id: Date
        let entries: [MealEntry]
        var total: Int { entries.reduce(0) { $0 + $1.deltaCalories } }
    }

    struct ChartPoint: Identifiable {
        let id = UUID()
        let time: Date
        let total: Int
    }

    func groupByDay(_ entries: [MealEntry]) -> [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.map { DayGroup(id: $0.key, entries: $0.value) }
            .sorted { $0.id > $1.id }
    }

    func chartPoints(for entries: [MealEntry], on date: Date) -> [ChartPoint] {
        let calendar = Calendar.current
        let dayEntries = entries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            .sorted { $0.timestamp < $1.timestamp }

        var runningTotal = 0
        return dayEntries.map { entry in
            runningTotal += entry.deltaCalories
            return ChartPoint(time: entry.timestamp, total: runningTotal)
        }
    }
}
