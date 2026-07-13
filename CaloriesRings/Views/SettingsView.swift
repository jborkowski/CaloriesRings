import SwiftUI

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var presenter = HealthIntegrationPresenter()

    var body: some View {
        NavigationStack {
            Form {
                Section("Apple Health") {
                    HStack(spacing: 12) {
                        Image(systemName: statusSymbol)
                            .foregroundStyle(statusColor)
                            .font(.title2)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(statusTitle).font(.headline)
                            Text(statusDetail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if canRequestAuthorization {
                        Button {
                            Task { await presenter.connect() }
                        } label: {
                            Label("Connect Apple Health", systemImage: "heart.fill")
                        }
                        .disabled(presenter.isWorking)
                    }

                    if presenter.isWorking {
                        HStack {
                            ProgressView()
                            Text("Working…").foregroundStyle(.secondary)
                        }
                    }

                    if let message = presenter.resultMessage {
                        Label(message, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    if let message = presenter.errorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Nutrition Shared") {
                    Label("Dietary energy", systemImage: "flame.fill")
                    Label("Protein, carbohydrates, and fat", systemImage: "chart.bar.fill")
                    Text("CaloriesRings only writes meals you log. It does not read your Apple Health data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if presenter.authorizationState == .denied ||
                    presenter.authorizationState == .partiallyAuthorized {
                    Section("Manage Access") {
                        Text("To change individual permissions, open Health, tap your profile, then Apps and Services, and choose CaloriesRings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .task { await presenter.refreshAuthorization() }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task { await presenter.refreshAuthorization() }
            }
        }
    }

    private var canRequestAuthorization: Bool {
        presenter.authorizationState == .notDetermined
    }

    private var statusTitle: String {
        switch presenter.authorizationState {
        case .unavailable: return "Unavailable"
        case .notDetermined: return "Not Connected"
        case .denied: return "Access Not Granted"
        case .partiallyAuthorized: return "Limited Access"
        case .authorized: return "Connected"
        }
    }

    private var statusDetail: String {
        switch presenter.authorizationState {
        case .unavailable:
            return "Apple Health is not available on this device."
        case .notDetermined:
            return "Connect to save logged meals in Apple Health."
        case .denied:
            return "Nutrition data cannot be saved until access changes."
        case .partiallyAuthorized:
            return "Only the nutrition categories you approved will sync."
        case .authorized:
            return "New meals automatically sync after you log them."
        }
    }

    private var statusSymbol: String {
        switch presenter.authorizationState {
        case .authorized: return "checkmark.circle.fill"
        case .partiallyAuthorized: return "exclamationmark.circle.fill"
        case .unavailable, .denied: return "xmark.circle.fill"
        case .notDetermined: return "heart.circle"
        }
    }

    private var statusColor: Color {
        switch presenter.authorizationState {
        case .authorized: return .green
        case .partiallyAuthorized: return .orange
        case .unavailable, .denied: return .red
        case .notDetermined: return .secondary
        }
    }
}
