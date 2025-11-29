import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appState: AppState
    @Query var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first,
               profile.onboardingCompletedAt != nil {
                MainTabView(profile: profile)
                    .environmentObject(appState)
            } else {
                OnboardingView()
            }
        }
    }
}
