import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first,
               profile.onboardingCompletedAt != nil {
                MainTabView(profile: profile)
                    .environment(appState)
            } else {
                OnboardingView()
            }
        }
        .onOpenURL { url in
            if url.scheme == "calorierings" && url.host == "log" {
                appState.showLogSheetFromDeepLink = true
            }
        }
    }
}
