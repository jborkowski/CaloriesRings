import SwiftUI
import SwiftData

@main
struct CalorieRingsApp: App {
    @State private var appState = AppState()
    @State private var initializationError: Error?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            MealEntry.self,
            SavedMealPreset.self
        ])

        let groupID = "group.me.thebo.calorierings"

        let containerURL: URL
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            containerURL = groupURL
        } else {
            containerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            print("Warning: App group '\(groupID)' not available. Using local storage. Widget will not sync.")
        }

        let storeURL = containerURL.appendingPathComponent("CalorieRings.store")
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        do {
            try SwiftDataStoreProtection.prepareStoreDirectory(at: containerURL)
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            SwiftDataStoreProtection.applyProtection(toStoreAt: storeURL)
            return container
        } catch {
            print("Critical Error: Failed to create persistent ModelContainer: \(error)")
            print("Falling back to in-memory storage. Data will not be saved.")

            let fallbackConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Failed to create even in-memory ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
