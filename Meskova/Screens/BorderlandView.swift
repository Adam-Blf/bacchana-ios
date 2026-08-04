import SwiftUI
import MeskovaCore

struct BorderlandView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var engine: BorderlandEngine?
    @State private var currentCard: Card?
    @State private var lastPenalty: PenaltyResult?
    @State private var currentPlayerIndex = 0
    @State private var isFlipped = false

    var body: some View {
        VStack(spacing: 24) {
            header

            Spacer()

            CardView(card: currentCard, isFlipped: isFlipped)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(reduceMotion ? nil : .easeInOut(duration: Theme.Motion.flip), value: isFlipped)

            if let penalty = lastPenalty {
                Text(penalty.displayText)
                    .font(Theme.Font.mono(18, weight: .bold))
                    .foregroundStyle(penalty.unit == .majorPenalty ? Theme.Color.neon : Theme.Color.ink)
            }

            Spacer()

            drawButton
        }
        .padding(20)
        .onAppear(perform: setupIfNeeded)
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

            if let engine {
                Text(engine.currentPlayer.name.uppercased())
                    .font(Theme.Font.body(15, weight: .bold))
                    .foregroundStyle(Theme.Color.ink)
            }

            Spacer()

            Button {
                appState.route = .recap
            } label: {
                Text("Récap")
                    .font(Theme.Font.body(13, weight: .medium))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(minHeight: 44)
        }
    }

    private var drawButton: some View {
        Button(action: drawCard) {
            Text("Tirer une carte")
                .font(Theme.Font.body(16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .foregroundStyle(Theme.Color.ink)
        .background(Theme.Color.neonDeep)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
    }

    private func setupIfNeeded() {
        guard engine == nil else { return }
        let players = appState.activePlayers.isEmpty ? appState.playerNames.map { Player(name: $0) } : appState.activePlayers
        engine = BorderlandEngine(players: players)
    }

    private func drawCard() {
        guard let engine else { return }
        isFlipped = false
        let drawnCard = engine.drawCard()
        let loser = engine.currentPlayer
        currentCard = drawnCard
        if let drawnCard {
            lastPenalty = engine.resolvePenalty(for: drawnCard, loser: loser)
        }
        withAnimation {
            isFlipped = true
        }
    }
}
