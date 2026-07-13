import Foundation
import Observation

@Observable
@MainActor
final class HealthIntegrationPresenter {
    var authorizationState: HealthKitAuthorizationState = .notDetermined
    var isWorking = false
    var resultMessage: String?
    var errorMessage: String?

    func refreshAuthorization() async {
        authorizationState = await HealthKitManager.shared.authorizationState()
    }

    func connect() async {
        isWorking = true
        resultMessage = nil
        errorMessage = nil

        do {
            authorizationState = try await HealthKitManager.shared.requestAuthorization()
            switch authorizationState {
            case .authorized:
                resultMessage = "Connected. New meals will be saved to Apple Health."
            case .partiallyAuthorized:
                resultMessage = "Connected with limited access. Only approved nutrition categories will sync."
            case .denied:
                errorMessage = "Access was not granted. You can change it from CaloriesRings app access in the Health app."
            case .unavailable:
                errorMessage = "Apple Health is not available on this device."
            case .notDetermined:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
            await refreshAuthorization()
        }

        isWorking = false
    }
}
