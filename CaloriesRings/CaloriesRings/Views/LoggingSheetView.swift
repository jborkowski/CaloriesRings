import SwiftUI
import SwiftData

struct LoggingSheetView: View {
    let initialMeal: MealType

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var presenter = LoggingPresenter()

    var body: some View {
        VStack(spacing: 16) {
            Text("Log calories").font(.headline)

            Picker("Meal", selection: $presenter.selectedMeal) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Text(meal.label).tag(meal)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                ForEach(presenter.presets, id: \.self) { value in
                    Button("+\(value)") { save(delta: value) }.buttonStyle(.bordered)
                }
                Button("-200") { save(delta: -200) }.buttonStyle(.bordered)
            }

            HStack {
                TextField("Exact kcal", text: $presenter.customCalories)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    if let v = Int(presenter.customCalories) { save(delta: v) }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear { presenter.selectedMeal = initialMeal }
        .alert("Error", isPresented: $presenter.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(presenter.errorMessage)
        }
    }

    private func save(delta: Int) {
        if presenter.save(delta: delta, context: context) { dismiss() }
    }
}
