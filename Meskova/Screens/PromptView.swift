import SwiftUI
import MeskovaCore

/// Generic screen for every content-pack driven mode (Picolo, Action/Vérité,
/// Tu préfères, etc). Borderland has its own dedicated card-flip screen.
struct PromptView: View {
    let packID: String

    @EnvironmentObject private var appState: AppState
    @State private var session: PromptSession?
    @State private var currentItem: PromptItem?
    @State private var currentPlayerIndex = 0
    @State private var activeRules: [ActiveRule] = []
    @State private var packTitle = ""

    var body: some View {
        VStack(spacing: 20) {
            header

            Spacer()

            if !activeRules.isEmpty {
                rulesBanner
            }

            if let targetLabel {
                targetBanner(targetLabel)
            }

            if let item = currentItem {
                promptCard(for: item)
            } else {
                Text("Pack indisponible.")
                    .font(Theme.Font.body(15))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }

            Spacer()

            actionButtons
        }
        .padding(20)
        .onAppear(perform: loadPackIfNeeded)
    }

    private var header: some View {
        HStack {
            Button {
                appState.route = .hub
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.Color.ink)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Retour au hub")

            Spacer()

            Text(packTitle.uppercased())
                .font(Theme.Font.body(13, weight: .medium))
                .foregroundStyle(Theme.Color.inkSecondary)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var rulesBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(activeRules) { rule in
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Theme.Color.neon)
                    Text(rule.text)
                        .font(Theme.Font.mono(12))
                        .foregroundStyle(Theme.Color.ink)
                    Spacer()
                    Text("\(rule.remainingTurns)")
                        .font(Theme.Font.mono(12, weight: .bold))
                        .foregroundStyle(Theme.Color.neon)
                }
            }
        }
        .padding(12)
        // backgroundRaised, pas surfaceElevated : orangeInk n'atteint que
        // 4.39:1 sur surfaceElevated en clair (sous l'AA 4.5:1), decouvert
        // par la garde de contraste. 4.53:1 sur backgroundRaised.
        .background(Theme.Color.backgroundRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
    }

    /// Cible de contenu (genre / statut relationnel / paire) : résolue de
    /// façon déterministe par tour (seed = item + numéro de tour, via le
    /// nombre de cartes déjà défaussées) pour ne jamais changer entre deux
    /// re-rendus du même tour. Reste gracieux - un prompt sans `targets`
    /// n'affiche aucune bannière. Mirrors `PromptGameScreen.tsx`.
    private var targetPlayers: [Player] {
        guard let item = currentItem, let target = item.targets, Targeting.isResolvable(target), let session else {
            return []
        }
        let seed = "\(item.id)-\(session.discardPile.count)"
        return Targeting.resolve(players: appState.activePlayers, target: target, rng: Targeting.seededRng(seed))
    }

    private var targetLabel: String? {
        switch targetPlayers.count {
        case 0:
            return nil
        case 1:
            return "C'est à \(targetPlayers[0].name) de jouer"
        default:
            return "C'est à \(targetPlayers.map(\.name).joined(separator: " et ")) de jouer"
        }
    }

    private func targetBanner(_ label: String) -> some View {
        HStack {
            Image(systemName: "target")
                .foregroundStyle(Theme.Color.orangeInk)
            Text(label)
                .font(Theme.Font.body(13, weight: .medium))
                .foregroundStyle(Theme.Color.orangeInk)
            Spacer()
        }
        .padding(12)
        // backgroundRaised, pas surfaceElevated : orangeInk n'atteint que
        // 4.39:1 sur surfaceElevated en clair (sous l'AA 4.5:1), decouvert
        // par la garde de contraste. 4.53:1 sur backgroundRaised.
        .background(Theme.Color.backgroundRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .accessibilityElement(children: .combine)
    }

    private func promptCard(for item: PromptItem) -> some View {
        let player = currentPlayerName
        let player2 = secondPlayerName
        let text = PromptSession.interpolate(item.text, player: player, player2: player2)

        return VStack(spacing: 16) {
            Text(text)
                .font(Theme.Font.display(28))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.cardInk)
                .padding(24)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(Theme.Color.cardFace)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadow(color: Theme.Color.neon.opacity(0.25), radius: 24)
        .accessibilityLabel(text)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: advance) {
                Text("Fait")
                    .font(Theme.Font.body(16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            // tileInk : fond quasi-plein (success a 85%), clair dans les 2 themes -
            // ink (thematisee) y tombe a 3.39:1 en sombre, sous le seuil AA.
            .foregroundStyle(Theme.Color.tileInk)
            .background(Theme.Color.success.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))

            Button(action: advance) {
                Text("Pénalité")
                    .font(Theme.Font.body(16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            // tileInk : fond neonDeep plein, clair dans les 2 themes.
            .foregroundStyle(Theme.Color.tileInk)
            .background(Theme.Color.neonDeep)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        }
    }

    private var currentPlayerName: String {
        guard !appState.playerNames.isEmpty else { return "Joueur" }
        return appState.playerNames[currentPlayerIndex % appState.playerNames.count]
    }

    private var secondPlayerName: String? {
        guard appState.playerNames.count > 1 else { return nil }
        let index = (currentPlayerIndex + 1) % appState.playerNames.count
        return appState.playerNames[index]
    }

    private func loadPackIfNeeded() {
        guard session == nil else { return }
        guard let pack = PackCatalog.loadFullPack(id: packID) else { return }
        packTitle = pack.pack.title
        let newSession = PromptSession(pack: pack)
        session = newSession
        currentItem = newSession.drawNext(playerCount: max(appState.playerNames.count, 1))
        activeRules = newSession.activeRules
    }

    private func advance() {
        guard let session else { return }
        session.tickTurn()
        currentPlayerIndex = (currentPlayerIndex + 1) % max(appState.playerNames.count, 1)
        currentItem = session.drawNext(playerCount: max(appState.playerNames.count, 1))
        activeRules = session.activeRules
    }
}
