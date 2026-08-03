import SwiftUI
import UIKit
import LaTaverneCore

/// La Criée - "L'Enchère". A theme is drawn, players bid out loud on how many
/// items they can name in a minute, until someone shouts "tu mens !". The
/// last bidder then has 60 seconds to cite their count. Embedded game mode:
/// no content pack, no named player, no recap. Mirrors
/// `la-taverne/src/components/screens/AuctionScreen.tsx`.
struct AuctionView: View {
    @EnvironmentObject private var appState: AppState

    private enum Phase {
        case bidding
        case challenge
        case result
    }

    private static let challengeSeconds = 60

    @State private var theme: AuctionTheme = AuctionContent.pickTheme(excluding: nil)
    @State private var phase: Phase = .bidding
    // La Criée ne nomme jamais le joueur puni (tout se joue à voix haute), donc
    // pas d'addition chiffrée : on compte les manches pour clôturer la session.
    @State private var roundsPlayed = 0
    @State private var bid = 0
    @State private var cited = 0
    @State private var secondsLeft = AuctionView.challengeSeconds
    @State private var success: Bool?
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            header

            Spacer()

            themeCard

            content

            Spacer()

            footer
        }
        .padding(20)
        .onDisappear(perform: stopTimer)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: handleQuit) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.Color.ink)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Quitter la Criée et revenir à l'accueil")

            Spacer()

            Text("LA CRIÉE")
                .font(Theme.Font.body(13, weight: .medium))
                .foregroundStyle(Theme.Color.inkSecondary)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    // MARK: - Theme

    private var themeCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "megaphone.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.Color.neon)
            Text("LE THÈME")
                .font(Theme.Font.mono(11, weight: .bold))
                .foregroundStyle(Theme.Color.inkMuted)
            Text(theme.text)
                .font(Theme.Font.display(22))
                .foregroundStyle(Theme.Color.cardInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.Color.cardFace)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .bidding:
            biddingContent
        case .challenge:
            challengeContent
        case .result:
            resultCard
        }
    }

    private var biddingContent: some View {
        VStack(spacing: 12) {
            Text("Annoncez à voix haute combien vous pouvez en citer en 1 minute. Surenchérissez… ou criez « tu mens ! »")
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)

            stepper(
                value: bid,
                onDecrement: { haptic(.light); bid = max(0, bid - 1) },
                onIncrement: { haptic(.light); bid += 1 },
                decrementLabel: "Baisser l'enchère",
                incrementLabel: "Monter l'enchère",
                accessibilityLabel: "Enchère actuelle : \(bid)"
            )

            Text("DERNIÈRE ENCHÈRE ANNONCÉE")
                .font(Theme.Font.mono(11, weight: .bold))
                .foregroundStyle(Theme.Color.inkMuted)
        }
        .padding(.top, 12)
    }

    private var challengeContent: some View {
        VStack(spacing: 12) {
            Text("\(secondsLeft)s")
                .font(Theme.Font.display(44))
                .foregroundStyle(secondsLeft <= 10 ? Theme.Color.cardRed : Theme.Color.ink)
                .accessibilityAddTraits(.updatesFrequently)

            Text("Cite-les ! La table valide chaque bonne réponse.")
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                controlButton(systemImage: "minus", label: "Retirer une bonne réponse", background: Theme.Color.surface, bordered: true) {
                    haptic(.light)
                    cited = max(0, cited - 1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(cited)")
                        .font(Theme.Font.display(40))
                        .foregroundStyle(Theme.Color.ink)
                    Text("/\(bid)")
                        .font(Theme.Font.body(18))
                        .foregroundStyle(Theme.Color.inkMuted)
                }
                .accessibilityElement(children: .combine)

                controlButton(systemImage: "plus", label: "Compter une bonne réponse", background: Theme.Color.neonSoft, bordered: true) {
                    handleCite()
                }
            }
        }
        .padding(.top, 12)
    }

    private var resultCard: some View {
        VStack(spacing: 10) {
            Text(success == true ? "Pari tenu !" : "Ça sentait le bluff…")
                .font(Theme.Font.display(24))
                .foregroundStyle(Theme.Color.ink)

            Text(resultDetail)
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(success == true ? Theme.Color.success.opacity(0.18) : Theme.Color.cardRed.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }

    private var resultDetail: String {
        let plural = { (count: Int) in count > 1 ? "s" : "" }
        if success == true {
            return "\(bid) cité\(plural(bid)) sur \(bid). Celui qui a crié « tu mens » prend \(bid) pénalité\(plural(bid))."
        }
        return "\(cited) cité\(plural(cited)) sur \(bid) annoncés. L'enchérisseur prend \(bid) pénalité\(plural(bid))."
    }

    // MARK: - Shared controls

    private func stepper(
        value: Int,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void,
        decrementLabel: String,
        incrementLabel: String,
        accessibilityLabel: String
    ) -> some View {
        HStack(spacing: 16) {
            controlButton(systemImage: "minus", label: decrementLabel, background: Theme.Color.surface, bordered: true, action: onDecrement)

            Text("\(value)")
                .font(Theme.Font.display(52))
                .foregroundStyle(Theme.Color.ink)
                .frame(minWidth: 80)
                .accessibilityLabel(accessibilityLabel)

            controlButton(systemImage: "plus", label: incrementLabel, background: Theme.Color.neonSoft, bordered: true, action: onIncrement)
        }
    }

    private func controlButton(
        systemImage: String,
        label: String,
        background: SwiftUI.Color,
        bordered: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.Color.ink)
                .frame(width: 48, height: 48)
        }
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .stroke(bordered ? Theme.Color.ink : .clear, lineWidth: 2)
        )
        .accessibilityLabel(label)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .bidding:
            VStack(spacing: 12) {
                primaryButton("« Tu mens ! » - lancer le chrono", systemImage: "timer", isDisabled: bid < 1, action: startChallenge)
                secondaryButton("Changer de thème", systemImage: "arrow.counterclockwise", action: nextRound)
            }
        case .challenge:
            secondaryButton("Arrêter le défi", systemImage: "stop.fill") {
                resolveChallenge(cited >= bid)
            }
        case .result:
            VStack(spacing: 12) {
                primaryButton("Nouveau thème", systemImage: "arrow.counterclockwise", action: nextRound)
                secondaryButton("Terminer la partie", systemImage: "door.left.hand.open", action: finishSession)
            }
        }
    }

    private func primaryButton(
        _ title: String,
        systemImage: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Theme.Font.body(16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .foregroundStyle(Theme.Color.ink)
        .background(Theme.Color.neonDeep)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .opacity(isDisabled ? 0.5 : 1)
        .disabled(isDisabled)
    }

    private func secondaryButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                    .font(Theme.Font.body(15, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .foregroundStyle(Theme.Color.ink)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
    }

    // MARK: - Actions

    private func startChallenge() {
        guard bid >= 1 else { return }
        haptic(.medium)
        cited = 0
        secondsLeft = Self.challengeSeconds
        success = nil
        phase = .challenge
        startTimer()
    }

    private func handleCite() {
        haptic(.light)
        let next = cited + 1
        cited = next
        if next >= bid {
            resolveChallenge(true)
        }
    }

    private func resolveChallenge(_ won: Bool) {
        stopTimer()
        success = won
        phase = .result
        roundsPlayed += 1
        haptic(.heavy)
    }

    private func nextRound() {
        haptic(.light)
        stopTimer()
        theme = AuctionContent.pickTheme(excluding: theme.id)
        bid = 0
        cited = 0
        secondsLeft = Self.challengeSeconds
        success = nil
        phase = .bidding
    }

    private func finishSession() {
        haptic(.medium)
        stopTimer()
        appState.analytics.track(
            "session_completed",
            properties: ["mode": "auction", "turns": String(roundsPlayed)]
        )
        appState.route = .hub
    }

    private func handleQuit() {
        stopTimer()
        appState.route = .hub
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                tick()
            }
        }
    }

    private func tick() {
        guard secondsLeft > 0 else {
            resolveChallenge(false)
            return
        }
        secondsLeft -= 1
        if secondsLeft == 0 {
            resolveChallenge(false)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
