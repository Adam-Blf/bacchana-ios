import Foundation
import Combine
import MeskovaCore

/// Genre et statut relationnel facultatifs saisis sur `WelcomeView`, avant
/// qu'un `Player` (MeskovaCore) n'existe. `Codable` pour la persistance
/// locale ; jamais transmis en analytics.
struct PlayerAttributes: Codable, Equatable {
    var gender: Player.Gender?
    var relationship: Player.Relationship?

    init(gender: Player.Gender? = nil, relationship: Player.Relationship? = nil) {
        self.gender = gender
        self.relationship = relationship
    }

    var isEmpty: Bool { gender == nil && relationship == nil }
}

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
        case ranking
        case wouldYouRather
        case recap
        case paywall
        case settings
    }

    @Published var route: Route = .welcome
    @Published var playerNames: [String] {
        didSet { persistPlayerNames() }
    }

    /// Attributs facultatifs déclarés par joueur (genre, statut relationnel),
    /// alignés par index sur `playerNames`. 100 % local, jamais envoyés en
    /// analytics (voir `MeskovaCore.Player.gender` / `.relationship`).
    @Published var playerAttributes: [PlayerAttributes] {
        didSet { persistPlayerAttributes() }
    }

    /// Préférence de thème clair/sombre/système, persistée comme sur le web
    /// (`themeStore.ts`). `nil` via `ThemeMode.system.colorScheme` laisse
    /// SwiftUI suivre l'OS en direct.
    @Published var themeMode: ThemeMode {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: themeModeKey) }
    }

    /// Consentement RGPD pour la mesure d'audience (PostHog), persisté et jamais pré-coché -
    /// mirroring the web's `consentStore`. Répercuté sur `analytics.isEnabled` à chaque
    /// changement, y compris au lancement (voir `init`), puisque `PostHogAnalytics` redémarre
    /// toujours opt-out par défaut.
    @Published var analyticsConsent: Bool {
        didSet {
            UserDefaults.standard.set(analyticsConsent, forKey: analyticsConsentKey)
            analytics.isEnabled = analyticsConsent
        }
    }

    /// Live `Player` instances for the current session, created once when a
    /// game mode starts so stat totals (penalties, contests) persist across
    /// screens and land on `RecapView`.
    @Published private(set) var activePlayers: [Player] = []

    let entitlements: EntitlementProviding
    let analytics: AnalyticsProviding

    // Prefix renamed from "lataverne." to "meskova." with the product rename (v0.14.0).
    // No migration needed: the app was never shipped to TestFlight or the App Store (no git
    // tag, no Apple Developer account yet - see README "Ce qu'il reste pour TestFlight"), so
    // no `UserDefaults` written under the old prefix exist outside ephemeral CI simulators.
    private let playerNamesKey = "meskova.playerNames"
    private let playerAttributesKey = "meskova.playerAttributes"
    private let themeModeKey = "meskova.themeMode"
    private let analyticsConsentKey = "meskova.analyticsConsent"

    init(entitlements: EntitlementProviding = EntitlementsFactory.make(),
         analytics: AnalyticsProviding = AnalyticsFactory.make()) {
        self.entitlements = entitlements
        self.analytics = analytics
        self.playerNames = UserDefaults.standard.stringArray(forKey: playerNamesKey) ?? []
        if let data = UserDefaults.standard.data(forKey: playerAttributesKey),
           let decoded = try? JSONDecoder().decode([PlayerAttributes].self, from: data) {
            self.playerAttributes = decoded
        } else {
            self.playerAttributes = []
        }
        let storedMode = UserDefaults.standard.string(forKey: themeModeKey).flatMap(ThemeMode.init(rawValue:))
        self.themeMode = storedMode ?? .system
        self.analyticsConsent = UserDefaults.standard.bool(forKey: analyticsConsentKey)
        // Property observers do not fire for a value set during `init`, so the analytics
        // provider is synced here explicitly - required for `PostHogAnalytics`, which always
        // restarts opt-out (see its `init`).
        self.analytics.isEnabled = self.analyticsConsent
    }

    private func persistPlayerNames() {
        UserDefaults.standard.set(playerNames, forKey: playerNamesKey)
    }

    private func persistPlayerAttributes() {
        guard let data = try? JSONEncoder().encode(playerAttributes) else { return }
        UserDefaults.standard.set(data, forKey: playerAttributesKey)
    }

    /// Attributs facultatifs pour le joueur à `index`, ou une valeur vide si
    /// rien n'a encore été déclaré (jamais requis pour jouer).
    func attributes(at index: Int) -> PlayerAttributes {
        guard playerAttributes.indices.contains(index) else { return PlayerAttributes() }
        return playerAttributes[index]
    }

    /// Met à jour les attributs d'un joueur par index, en complétant le
    /// tableau si besoin (ex. joueur ajouté après coup).
    func setAttributes(_ attributes: PlayerAttributes, at index: Int) {
        while playerAttributes.count <= index {
            playerAttributes.append(PlayerAttributes())
        }
        playerAttributes[index] = attributes
    }

    /// Adds a player name, keeping `playerAttributes` aligned by index.
    func addPlayerName(_ name: String) {
        playerNames.append(name)
    }

    /// Removes a player name and its attributes together so indices never
    /// drift out of sync after a removal in the middle of the roster.
    func removePlayerName(at index: Int) {
        guard playerNames.indices.contains(index) else { return }
        playerNames.remove(at: index)
        if playerAttributes.indices.contains(index) {
            playerAttributes.remove(at: index)
        }
    }

    /// Creates fresh `Player` stat trackers from the current roster, applying
    /// each player's optional gender/relationship declared on `WelcomeView`.
    /// Safe to call every time the group re-enters the Hub from Welcome.
    func startSession() {
        activePlayers = playerNames.enumerated().map { index, name in
            let player = Player(name: name)
            let attrs = attributes(at: index)
            player.gender = attrs.gender
            player.relationship = attrs.relationship
            return player
        }
    }

    var canStart: Bool {
        playerNames.count >= 2
    }

    /// Efface la tablée (joueurs, attributs, session en cours) sur cet appareil, sans jamais
    /// toucher au statut premium ni au consentement analytics - appelé depuis `SettingsView`
    /// après confirmation, mirroring the web's `clearPlayers()` + `resetGame()`.
    func resetTablee() {
        playerNames = []
        playerAttributes = []
        activePlayers = []
    }
}
