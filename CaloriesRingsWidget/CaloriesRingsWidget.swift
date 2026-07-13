//
//  CaloriesRingsWidget.swift
//  CaloriesRingsWidget
//
//  Simplified static widget so the project compiles
//

import WidgetKit
import SwiftUI
import SwiftData

struct CalorieEntry: TimelineEntry {
    let date: Date
    let totalCalories: Int
    let dailyGoal: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), totalCalories: 1200, dailyGoal: 1800)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (CalorieEntry) -> Void
    ) {
        completion(placeholder(in: context))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<CalorieEntry>) -> Void
    ) {
        let now = Date()

        let summary = loadTodayWidgetSummary()

        let entry = CalorieEntry(
            date: now,
            totalCalories: summary.totalCalories,
            dailyGoal: summary.dailyGoal
        )

        let next = Calendar.current.date(byAdding: .minute, value: 15, to: now)
        let refreshDate = next ?? now.addingTimeInterval(15 * 60)

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

private struct WidgetSummary {
    let totalCalories: Int
    let dailyGoal: Int
}

private func loadTodayWidgetSummary() -> WidgetSummary {
    let schema = Schema([
        UserProfile.self,
        MealEntry.self
    ])

    let groupID = "group.me.thebo.calorierings"

    guard let containerURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
        return WidgetSummary(totalCalories: 0, dailyGoal: 0)
    }

    let storeURL = containerURL.appendingPathComponent("CalorieRings.store")

    let configuration = ModelConfiguration(
        schema: schema,
        url: storeURL,
        cloudKitDatabase: .none
    )

    do {
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let context = ModelContext(container)

        let startOfToday = Calendar.current.startOfDay(for: Date())
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
        let descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate<MealEntry> { entry in
                entry.timestamp >= startOfToday && entry.timestamp < endOfToday
            }
        )
        let todayEntries = try context.fetch(descriptor)
        let total = todayEntries.reduce(0) { $0 + $1.deltaCalories }

        let profilesDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(profilesDescriptor)
        let dailyGoal = profiles.first?.dailyCalorieGoal ?? 0

        return WidgetSummary(totalCalories: total, dailyGoal: dailyGoal)
    } catch {
        return WidgetSummary(totalCalories: 0, dailyGoal: 0)
    }
}

struct CaloriesRingsWidgetEntryView: View {
    let entry: CalorieEntry

    private var progress: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(Double(entry.totalCalories) / Double(entry.dailyGoal), 1.5)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Today")
                .font(.headline)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color(for: progress),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(entry.totalCalories)")
                        .font(.headline)
                    if entry.dailyGoal > 0 {
                        Text("/ \(entry.dailyGoal) kcal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 80, height: 80)

            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func color(for progress: Double) -> Color {
        let percent = progress * 100
        if percent <= 100 { return .green }
        if percent <= 130 { return .yellow }
        return .red
    }
}

struct CaloriesRingsWidget: Widget {
    let kind: String = "CaloriesRingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            CaloriesRingsWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "calorierings://log"))
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calorie Rings")
        .description("See today's total calories.")
    }
}


