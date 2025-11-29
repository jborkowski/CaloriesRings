import SwiftUI
import SwiftData

@main
struct CalorieRingsApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            MealEntry.self
        ])
       
        let groupID = "group.me.thebo.calorierings"
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            fatalError("Unable to find app group container for \(groupID)")
        }
        let storeURL = containerURL.appendingPathComponent("CalorieRings.store")
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}


