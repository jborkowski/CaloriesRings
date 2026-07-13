import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    var showLogSheetFromDeepLink: Bool = false
}
