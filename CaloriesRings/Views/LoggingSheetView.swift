import SwiftData
import SwiftUI

struct LoggingSheetView: View {
    let initialMeal: MealType

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedMealPreset.createdAt, order: .reverse) private var savedPresets: [SavedMealPreset]
    @State private var presenter = LoggingPresenter()
    @State private var showingPhotoAnalysis = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var selectedMealPresets: [SavedMealPreset] {
        savedPresets.filter { $0.mealType == presenter.selectedMeal }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Button {
                        showingPhotoAnalysis = true
                    } label: {
                        Label("Scan food with AI", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal").font(.headline)
                        Picker("Meal", selection: $presenter.selectedMeal) {
                            ForEach(MealType.allCases, id: \.self) { meal in
                                Text(meal.label).tag(meal)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if !selectedMealPresets.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("My \(presenter.selectedMeal.label.lowercased()) presets").font(.headline)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(selectedMealPresets) { preset in
                                    Button {
                                        save(savedPreset: preset)
                                    } label: {
                                        mealPresetCard(mealPreset(from: preset))
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            presenter.delete(savedPreset: preset, context: context)
                                        }
                                    }
                                    .accessibilityLabel("\(preset.name), \(preset.portionDescription), \(preset.calories) calories")
                                    .accessibilityHint("Adds \(preset.calories) calories to \(presenter.selectedMeal.label)")
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default meals").font(.headline)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(presenter.mealPresets) { preset in
                                Button {
                                    save(preset: preset)
                                } label: {
                                    mealPresetCard(preset)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(preset.name), \(preset.portionDescription), \(preset.calories) calories")
                                .accessibilityHint("Adds \(preset.calories) calories to \(presenter.selectedMeal.label)")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick calories").font(.headline)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(presenter.caloriePresets, id: \.self) { value in
                                Button {
                                    save(delta: value)
                                } label: {
                                    Text("+\(value) kcal").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            Button {
                                save(delta: -200)
                            } label: {
                                Text("−200 kcal").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom amount").font(.headline)
                        HStack {
                            TextField("Exact kcal", text: $presenter.customCalories)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Button("Add") {
                                if let value = Int(presenter.customCalories) {
                                    save(delta: value)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(Int(presenter.customCalories) == nil)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Log calories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { presenter.selectedMeal = initialMeal }
        .sheet(isPresented: $showingPhotoAnalysis) {
            PhotoAnalysisSheetView(initialMeal: presenter.selectedMeal)
        }
        .alert("Error", isPresented: $presenter.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(presenter.errorMessage)
        }
    }

    private func mealPreset(from savedPreset: SavedMealPreset) -> MealPreset {
        MealPreset(
            id: savedPreset.id.uuidString,
            name: savedPreset.name,
            portionDescription: savedPreset.portionDescription,
            symbol: savedPreset.symbol,
            calories: savedPreset.calories,
            proteinGrams: savedPreset.proteinGrams,
            carbsGrams: savedPreset.carbsGrams,
            fatGrams: savedPreset.fatGrams
        )
    }

    private func mealPresetCard(_ preset: MealPreset) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                if preset.symbol.contains(".") {
                    Image(systemName: preset.symbol).font(.title2)
                } else {
                    Text(preset.symbol).font(.title2)
                }
                Spacer()
                Text("\(preset.calories) kcal")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            Text(preset.name)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(preset.portionDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Text("P \(preset.proteinGrams, specifier: "%.1f")g  C \(preset.carbsGrams, specifier: "%.1f")g  F \(preset.fatGrams, specifier: "%.1f")g")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }

    private func save(delta: Int) {
        if presenter.save(delta: delta, context: context) { dismiss() }
    }

    private func save(preset: MealPreset) {
        if presenter.save(preset: preset, context: context) { dismiss() }
    }

    private func save(savedPreset: SavedMealPreset) {
        if presenter.save(savedPreset: savedPreset, context: context) { dismiss() }
    }
}
