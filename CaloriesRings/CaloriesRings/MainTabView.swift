import SwiftUI
import SwiftData
import Charts
import WidgetKit

struct MainTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            TodayView(profile: profile)
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            HistoryView(profile: profile)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
    }
}

// MARK: - Today

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MealEntry.timestamp, order: .forward) private var entries: [MealEntry]

    let profile: UserProfile
    @State private var showingLogSheet = false
    @State private var activeMeal: MealType = .breakfast

    private var currentMealByTime: MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }

    var body: some View {
        let todayTotals = totalsForToday()
        let dayTotal = todayTotals.total
        let dayZone = dailyZone(total: dayTotal)

        VStack(spacing: 24) {
            Text("Today")
                .font(.largeTitle.bold())

            // Big active meal ring in center
            ActiveMealRingView(
                meal: activeMeal,
                totals: todayTotals,
                profile: profile
            )
            .frame(height: 200)

            // Smaller rings for other meals
            HStack(spacing: 16) {
                ForEach([MealType.breakfast, .lunch, .dinner], id: \.self) { meal in
                    if meal != activeMeal {
                        SmallMealRingView(
                            meal: meal,
                            totals: todayTotals,
                            profile: profile
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeMeal = meal
                            }
                        }
                    }
                }
            }
            .frame(height: 90)

            // Daily total + zone indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(color(for: dayZone))
                    .frame(width: 10, height: 10)
                Text("Total: \(dayTotal) / \(profile.dailyCalorieGoal) kcal")
                    .font(.title3)
            }

            // Snacks summary
            if todayTotals.snack != 0 {
                Text("Snacks: \(todayTotals.snack) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: { showingLogSheet = true }) {
                Label("Log \(label(for: activeMeal))", systemImage: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear {
            // Initialize active meal based on time when view appears
            activeMeal = currentMealByTime
        }
        .sheet(isPresented: $showingLogSheet) {
            LoggingSheetView(initialMeal: activeMeal) { entry in
                context.insert(entry)
                try? context.save()
            }
            .presentationDetents([.fraction(0.35)])
        }
    }

    private func label(for meal: MealType) -> String {
        switch meal {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    private func totalsForToday() -> (breakfast: Int, lunch: Int, dinner: Int, snack: Int, total: Int) {
        let calendar = Calendar.current
        let todayEntries = entries.filter { calendar.isDateInToday($0.timestamp) }

        func total(for type: MealType) -> Int {
            todayEntries
                .filter { $0.mealType == type }
                .reduce(0) { $0 + $1.deltaCalories }
        }

        let b = total(for: .breakfast)
        let l = total(for: .lunch)
        let d = total(for: .dinner)
        let s = total(for: .snack)
        let all = b + l + d + s
        return (b, l, d, s, all)
    }

    private enum DayZone { case green, yellow, red }

    private func dailyZone(total: Int) -> DayZone {
        let percent = Double(total) / Double(max(profile.dailyCalorieGoal, 1)) * 100.0
        if percent <= Double(profile.greenUpperPercent) { return .green }
        if percent <= Double(profile.yellowUpperPercent) { return .yellow }
        return .red
    }

    private func color(for zone: DayZone) -> Color {
        switch zone {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}

// MARK: - Active and small meal rings

struct ActiveMealRingView: View {
    let meal: MealType
    let totals: (breakfast: Int, lunch: Int, dinner: Int, snack: Int, total: Int)
    let profile: UserProfile

    private var total: Int {
        switch meal {
        case .breakfast: return totals.breakfast
        case .lunch: return totals.lunch
        case .dinner: return totals.dinner
        case .snack: return totals.snack
        }
    }

    private var target: Int {
        switch meal {
        case .breakfast: return profile.breakfastTarget
        case .lunch: return profile.lunchTarget
        case .dinner: return profile.dinnerTarget
        case .snack: return profile.snackTarget
        }
    }

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(total) / Double(target), 1.5)
    }

    private var zoneColor: Color {
        guard target > 0 else { return .gray }
        let percent = Double(total) / Double(target) * 100.0
        if percent <= 100 { return .green }
        if percent <= 130 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(zoneColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(total)")
                        .font(.title)
                    Text("/ \(target) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title(for: meal))
                .font(.headline)
        }
    }

    private func title(for meal: MealType) -> String {
        switch meal {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
}

struct SmallMealRingView: View {
    let meal: MealType
    let totals: (breakfast: Int, lunch: Int, dinner: Int, snack: Int, total: Int)
    let profile: UserProfile

    private var total: Int {
        switch meal {
        case .breakfast: return totals.breakfast
        case .lunch: return totals.lunch
        case .dinner: return totals.dinner
        case .snack: return totals.snack
        }
    }

    private var target: Int {
        switch meal {
        case .breakfast: return profile.breakfastTarget
        case .lunch: return profile.lunchTarget
        case .dinner: return profile.dinnerTarget
        case .snack: return profile.snackTarget
        }
    }

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(total) / Double(target), 1.5)
    }

    private var zoneColor: Color {
        guard target > 0 else { return .gray }
        let percent = Double(total) / Double(target) * 100.0
        if percent <= 100 { return .green }
        if percent <= 130 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(zoneColor.opacity(0.8), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 60, height: 60)

            Text(shortTitle(for: meal))
                .font(.caption2)
        }
    }

    private func shortTitle(for meal: MealType) -> String {
        switch meal {
        case .breakfast: return "B"
        case .lunch: return "L"
        case .dinner: return "D"
        case .snack: return "S"
        }
    }
}

// MARK: - History

struct HistoryView: View {
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var entries: [MealEntry]

    let profile: UserProfile

    var body: some View {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        let days = grouped.keys.sorted(by: >)

        NavigationStack {
            List(days, id: \.self) { day in
                let dayEntries = grouped[day] ?? []
                let total = dayEntries.reduce(0) { $0 + $1.deltaCalories }

                NavigationLink {
                    DayDetailView(date: day, entries: dayEntries, profile: profile)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(day, style: .date)
                            Text("\(total) kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct DayDetailView: View {
    let date: Date
    let entries: [MealEntry]
    let profile: UserProfile

    private var points: [ChartData] {
        let calendar = Calendar.current
        let dayEntries = entries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            .sorted { $0.timestamp < $1.timestamp }

        var runningTotal = 0
        var result: [ChartData] = []

        for e in dayEntries {
            runningTotal += e.deltaCalories
            result.append(ChartData(time: e.timestamp, total: runningTotal))
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(date, style: .date)
                .font(.title2.bold())

            if points.isEmpty {
                Text("No entries for this day")
                    .foregroundStyle(.secondary)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Calories", point.total)
                    )
                }
                .frame(height: 220)

                if let last = points.last {
                    Text("Total: \(last.total) / \(profile.dailyCalorieGoal) kcal")
                        .font(.headline)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ChartData: Identifiable {
    let id = UUID()
    let time: Date
    let total: Int
}

// MARK: - Logging sheet

struct LoggingSheetView: View {
    let initialMeal: MealType
    let onSave: (MealEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedMeal: MealType = .breakfast
    @State private var customCalories: String = ""

    private let presets = [100, 200, 300, 400]

    var body: some View {
        VStack(spacing: 16) {
            Text("Log calories")
                .font(.headline)

            Picker("Meal", selection: $selectedMeal) {
                Text("Breakfast").tag(MealType.breakfast)
                Text("Lunch").tag(MealType.lunch)
                Text("Dinner").tag(MealType.dinner)
                Text("Snack").tag(MealType.snack)
            }
            .pickerStyle(.segmented)

            HStack {
                ForEach(presets, id: \.self) { value in
                    Button("+\(value)") {
                        save(delta: value)
                    }
                    .buttonStyle(.bordered)
                }

                Button("-200") {
                    save(delta: -200)
                }
                .buttonStyle(.bordered)
            }

            HStack {
                TextField("Exact kcal", text: $customCalories)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    if let v = Int(customCalories) {
                        save(delta: v)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            selectedMeal = initialMeal
        }
    }

    private func save(delta: Int) {
        let entry = MealEntry(mealType: selectedMeal, deltaCalories: delta)
        onSave(entry)

        // Ask widgets to refresh with latest data
        WidgetCenter.shared.reloadTimelines(ofKind: "CalorieRingsWidget")

        dismiss()
    }
}
