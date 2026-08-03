import Foundation
import Combine
import LaTaverneCore

/// Top-level app navigation state and player roster, persisted lightly via
/// `UserDefaults` so a group does not re-type names between sessions.
@MainActor
final class AppState: ObservableObject {
    enum Route: Equatable {
        case welcome
        case hub
        case borderland
        case prompt(packID: String)
        case roulette
        case tribunal
        case auction
        case quiz
        case recap
    }

    @Published var route: Route = .welcome
    @Published var playerNames: [String] {
        didSet { persistPlayerNames() }
    }

    /// Live `Player` instances for the current session, created once when a
    /// game mode starts so stat totals (penalties, contests) persist across
    /// screens and land on `RecapView`.
    @Published private(set) var activePlayers: [Player] = []

    let entitlements: EntitlementProviding
    let analytics: AnalyticsProviding

    private let playerNamesKey = "lataverne.playerNames"

    init(entitlements: EntitlementProviding = StubEntitlements(),
         analytics: AnalyticsProviding = StubAnalytics()) {
        self.entitlements = entitlements
        self.analytics = analytics
        self.playerNames = UserDefaults.standard.stringArray(forKey: playerNamesKey) ?? []
    }

    private func persistPlayerNames() {
        UserDefaults.standard.set(playerNames, forKey: playerNamesKey)
    }

    /// Creates fresh `Player` stat trackers from the current roster. Safe to
    /// call every time the group re-enters the Hub from Welcome.
    func startSession() {
        activePlayers = playerNames.map { Player(name: $0) }
    }

    var canStart: Bool {
        playerNames.count >= 2
    }
}
