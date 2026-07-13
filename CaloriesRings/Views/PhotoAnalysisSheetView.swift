import SwiftUI
import SwiftData

struct PhotoAnalysisSheetView: View {
    let initialMeal: MealType

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var presenter = PhotoAnalysisPresenter()
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scan Food")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .onAppear { presenter.selectedMeal = initialMeal; showingCamera = true }
        .sheet(isPresented: $showingCamera, onDismiss: handleImageSelected) {
            ImagePicker(selectedImage: $capturedImage)
        }
        .alert("Enter Z.AI API Key", isPresented: $presenter.showingAPIKeyAlert) {
            TextField("sk-...", text: $presenter.apiKeyInput)
            Button("Save") { presenter.saveAPIKey() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Get your free API key at api.z.ai")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch presenter.state {
        case .idle:
            Button("Take Photo") { showingCamera = true }
                .buttonStyle(.borderedProminent)

        case .analyzing:
            VStack(spacing: 16) {
                ProgressView()
                Text("Analyzing food…").foregroundStyle(.secondary)
            }

        case .result(let estimate):
            estimateView(estimate)

        case .error(let msg):
            VStack(spacing: 16) {
                Text(msg).foregroundStyle(.red).multilineTextAlignment(.center)
                Button("Try Again") { showingCamera = true }
            }.padding()
        }
    }

    private func estimateView(_ estimate: MacroEstimate) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(height: 180).clipped().cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(estimate.foodName).font(.title3).bold()
                    Text(estimate.servingSize).foregroundStyle(.secondary)
                    if let notes = estimate.notes {
                        Text(notes).font(.caption).foregroundStyle(.secondary)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                    GridRow {
                        macroCell(label: "Calories", value: "\(estimate.calories)", unit: "kcal", color: .orange)
                        macroCell(label: "Protein",  value: String(format: "%.1f", estimate.proteinG), unit: "g", color: .blue)
                    }
                    GridRow {
                        macroCell(label: "Carbs", value: String(format: "%.1f", estimate.carbsG), unit: "g", color: .yellow)
                        macroCell(label: "Fat",   value: String(format: "%.1f", estimate.fatG),   unit: "g", color: .red)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                confidenceBadge(estimate.confidence)

                Picker("Meal", selection: $presenter.selectedMeal) {
                    ForEach(MealType.allCases, id: \.self) { Text($0.label).tag($0) }
                }.pickerStyle(.segmented)

                Button("Accept") {
                    if presenter.accept(estimate: estimate, context: context) { dismiss() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Re-take") { capturedImage = nil; presenter.reset(); showingCamera = true }
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func macroCell(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title2).bold().foregroundStyle(color)
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func confidenceBadge(_ confidence: String) -> some View {
        let color: Color = confidence == "high" ? .green : confidence == "medium" ? .yellow : .red
        return Label(confidence.capitalized + " confidence", systemImage: "brain")
            .font(.caption).foregroundStyle(color)
    }

    private func handleImageSelected() {
        guard let image = capturedImage else { return }
        presenter.analyze(image: image)
    }
}
