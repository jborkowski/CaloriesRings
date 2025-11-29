import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var showLogSheetFromDeepLink: Bool = false
}
