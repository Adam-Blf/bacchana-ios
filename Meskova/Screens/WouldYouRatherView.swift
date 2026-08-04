import SwiftUI
import UIKit
import MeskovaCore

/// Tu préfères - dilemme A ou B à mécanique de vote. Le téléphone tourne,
/// chaque joueur actif tape son camp en privé. Au reveal, la minorité
/// trinque ; égalité parfaite ou vote unanime, personne ne trinque. Mirrors
/// `la-taverne/src/components/screens/WouldYouRatherScreen.tsx`.
///
/// The mode keeps its own local `penaltyCounts` via `WouldYouRatherSessionState`
/// and never touches `Player.penalties`, so the finished state renders its
/// own recap instead of the shared `RecapView`.
struct WouldYouRatherView: View {
    @EnvironmentObject private var appState: AppState

    @State private var session: WouldYouRatherSessionState?

    private var activePlayers: [Player] {
        session?.players ?? appState.activePlayers.filter(\.active)
    }

    /// Prochain joueur qui n'a pas encore voté pour la manche en cours.
    private var currentVoter: Player? {
        guard let session else { return nil }
        return session.players.first { session.votes[$0.id] == nil }
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            Spacer()

            content

            Spacer()

            footer
        }
        .padding(20)
        .onAppear(perform: startSessionIfNeeded)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: exitToHub) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Theme.Color.ink)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Quitter Tu préfères et revenir à l'accueil")

                Spacer()

                VStack(spacing: 2) {
                    Text("TU PRÉFÈRES")
                        .font(Theme.Font.body(13, weight: .medium))
                        .foregroundStyle(Theme.Color.inkSecondary)
                    if let session, session.phase == .voting, let currentVoter {
                        Text(currentVoter.name)
                            .font(Theme.Font.display(20))
                            .foregroundStyle(Theme.Color.ink)
                    }
                }

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }

            if let session, session.phase != .finished {
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 12))
                        Text("Votes : \(session.votes.count)/\(session.players.count)")
                            .font(Theme.Font.mono(12, weight: .bold))
                    }
                    .foregroundStyle(Theme.Color.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Color.neonSoft.opacity(0.35))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.Color.ink, lineWidth: 2))

                    Text("\(session.roundNumber)/\(session.roundNumber + session.queue.count)")
                        .font(Theme.Font.mono(11))
                        .foregroundStyle(Theme.Color.inkMuted)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let session {
            switch session.phase {
            case .voting:
                if let question = session.currentQuestion, let currentVoter {
                    votingCard(question: question, voter: currentVoter)
                }
            case .reveal:
                if let question = session.currentQuestion {
                    revealCard(session: session, question: question)
                }
            case .finished:
                WouldYouRatherRecapView(
                    players: activePlayers,
                    penaltyCounts: session.penaltyCounts,
                    onReplay: replaySession,
                    onQuit: exitToHub
                )
            }
        }
    }

    private func votingCard(question: WouldYouRatherQuestion, voter: Player) -> some View {
        VStack(spacing: 16) {
            Text("Passe le téléphone à \(voter.name)")
                .font(Theme.Font.mono(11, weight: .bold))
                .foregroundStyle(Theme.Color.inkSecondary)
                .textCase(.uppercase)

            optionButton(text: question.optionA, systemImage: "a.circle.fill") {
                handleVote(playerId: voter.id, side: .optionA)
            }

            Text("OU")
                .font(Theme.Font.display(16))
                .foregroundStyle(Theme.Color.inkMuted)

            optionButton(text: question.optionB, systemImage: "b.circle.fill") {
                handleVote(playerId: voter.id, side: .optionB)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.Color.cardFace)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
    }

    private func optionButton(text: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                Text(text)
                    .font(Theme.Font.body(16, weight: .medium))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .foregroundStyle(Theme.Color.cardInk)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
    }

    private func revealCard(session: WouldYouRatherSessionState, question: WouldYouRatherQuestion) -> some View {
        let counts = countVotes(session)
        let losingSide = minoritySide(session)
        return VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.Color.ink)

            splitRow(label: question.optionA, count: counts.optionA, isMinority: losingSide == .optionA)
            splitRow(label: question.optionB, count: counts.optionB, isMinority: losingSide == .optionB)

            Text(revealText(session: session, losingSide: losingSide))
                .font(Theme.Font.mono(11, weight: .bold))
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.Color.neonSoft.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
    }

    private func splitRow(label: String, count: Int, isMinority: Bool) -> some View {
        HStack {
            Text(label)
                .font(Theme.Font.body(14, weight: .medium))
                .foregroundStyle(Theme.Color.cardInk)
                .multilineTextAlignment(.leading)
            Spacer()
            Text("\(count)")
                .font(Theme.Font.mono(16, weight: .bold))
                .foregroundStyle(isMinority ? Theme.Color.premium : Theme.Color.inkSecondary)
        }
        .padding(12)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
    }

    private func revealText(session: WouldYouRatherSessionState, losingSide: WouldYouRatherSide?) -> String {
        guard losingSide != nil else {
            return "Égalité ou unanimité : personne ne trinque !"
        }
        let losers = session.players.filter { session.votes[$0.id] == losingSide }
        let names = losers.map(\.name).joined(separator: ", ")
        return "\(names) dans la minorité : pénalité pour la table !"
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        if let session {
            switch session.phase {
            case .voting, .finished:
                EmptyView()
            case .reveal:
                primaryButton("Manche suivante", systemImage: "arrow.right", action: handleNextRound)
            }
        }
    }

    private func primaryButton(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
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
    }

    // MARK: - Actions

    private func startSessionIfNeeded() {
        guard session == nil else { return }
        session = createWouldYouRatherSession(questions: WouldYouRatherContent.questions, players: appState.activePlayers)
    }

    private func handleVote(playerId: String, side: WouldYouRatherSide) {
        haptic(.light)
        guard let session else { return }
        var next = castVote(session, playerId: playerId, side: side)
        if allVoted(next) {
            next = revealVotes(next)
        }
        self.session = next
    }

    private func handleNextRound() {
        haptic(.medium)
        session = session.map { nextRound($0) }
    }

    private func replaySession() {
        session = createWouldYouRatherSession(questions: WouldYouRatherContent.questions, players: appState.activePlayers)
    }

    private func exitToHub() {
        appState.analytics.track(
            "session_completed",
            properties: ["mode": "wouldYouRather", "turns": String(session?.roundNumber ?? 0)]
        )
        appState.route = .hub
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// Local recap for Tu préfères: `Player.penalties` never gets mutated by this
/// mode, so the addition is built straight from
/// `WouldYouRatherSessionState.penaltyCounts` instead of routing through the
/// shared `RecapView`.
private struct WouldYouRatherRecapView: View {
    let players: [Player]
    let penaltyCounts: [String: Int]
    let onReplay: () -> Void
    let onQuit: () -> Void

    private var ranked: [(player: Player, count: Int)] {
        players
            .map { ($0, penaltyCounts[$0.id] ?? 0) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("L'ADDITION FINALE")
                .font(Theme.Font.display(26))
                .foregroundStyle(Theme.Color.ink)

            if ranked.allSatisfy({ $0.count == 0 }) {
                Text("Personne n'a été minoritaire ce soir.")
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.Color.inkSecondary)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(ranked.enumerated()), id: \.element.player.id) { index, entry in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(Theme.Font.mono(16, weight: .bold))
                                .foregroundStyle(index == 0 && entry.count > 0 ? Theme.Color.premium : Theme.Color.inkSecondary)
                                .frame(width: 24)
                            Text(entry.player.name)
                                .font(Theme.Font.body(15, weight: .medium))
                                .foregroundStyle(Theme.Color.ink)
                            Spacer()
                            Text("\(entry.count) pénalité\(entry.count > 1 ? "s" : "")")
                                .font(Theme.Font.mono(12))
                                .foregroundStyle(Theme.Color.inkSecondary)
                        }
                        .padding(14)
                        .background(Theme.Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: onReplay) {
                    Text("Nouveau tour")
                        .font(Theme.Font.body(16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .foregroundStyle(Theme.Color.ink)
                .background(Theme.Color.neonDeep)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))

                Button(action: onQuit) {
                    Text("Retour au hub")
                        .font(Theme.Font.body(15, weight: .medium))
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
        }
    }
}
