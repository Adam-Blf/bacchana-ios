import SwiftUI
import UIKit
import BacchusCore

/// Le Tableau d'Honneur - un juge découvre une question secrète et classe les
/// autres joueurs selon elle. Le groupe voit le podium et doit retrouver la
/// vraie question parmi quatre propositions. Trouvé : le juge prend les
/// pénalités. Raté : tout le groupe en prend une chacun. Mirrors
/// `bacchus-site/src/components/screens/RankingScreen.tsx`.
///
/// The mode keeps its own local `penaltyCounts` via `RankingSessionState` and
/// never touches `Player.penalties`, so the finished state renders its own
/// recap instead of the shared `RecapView`. Requires 4+ players (gated in
/// `HubView`), so the podium always excludes the judge and still has enough
/// contestants to rank.
struct RankingView: View {
    @EnvironmentObject private var appState: AppState

    @State private var session: RankingSessionState?

    private var activePlayers: [Player] {
        session?.players ?? appState.activePlayers.filter(\.active)
    }

    private var judge: Player? {
        session.flatMap { getJudge($0) }
    }

    private var contestants: [Player] {
        session.map { getContestants($0) } ?? []
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
        HStack {
            Button(action: exitToHub) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.Color.ink)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Quitter le Tableau d'Honneur et revenir à l'accueil")

            Spacer()

            if let session, session.phase != .finished {
                Text("LE TABLEAU D'HONNEUR - MANCHE \(session.roundNumber)")
                    .font(Theme.Font.body(12, weight: .medium))
                    .foregroundStyle(Theme.Color.inkSecondary)
                    .textCase(.uppercase)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let session {
            switch session.phase {
            case .handoff:
                handoffCard
            case .judging:
                if let round = session.round {
                    judgingCard(session: session, round: round)
                }
            case .return:
                returnCard
            case .guessing, .reveal:
                if let round = session.round {
                    guessingCard(session: session, round: round)
                }
            case .finished:
                RankingRecapView(
                    players: activePlayers,
                    penaltyCounts: session.penaltyCounts,
                    onReplay: replaySession,
                    onQuit: exitToHub
                )
            }
        }
    }

    private var handoffCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.Color.ink)
            Text("Personne d'autre ne regarde !")
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.Color.inkSecondary)
            Text("Passe le téléphone à \(judge?.name ?? "")")
                .font(Theme.Font.display(26))
                .foregroundStyle(Theme.Color.ink)
                .multilineTextAlignment(.center)
            Text("\(judge?.name ?? "Le joueur") est le juge de cette manche : une question secrète l'attend.")
                .font(Theme.Font.body(13))
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)
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

    private func judgingCard(session: RankingSessionState, round: RankingRound) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Question secrète - chut !")
                    .font(Theme.Font.mono(10, weight: .bold))
                    // cardInk (fixe) attenue : pose directement sur cardFace.
                    .foregroundStyle(Theme.Color.cardInk.opacity(0.7))
                    .textCase(.uppercase)
                Text(round.question.text)
                    .font(Theme.Font.body(16, weight: .medium))
                    .foregroundStyle(Theme.Color.cardInk)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Theme.Color.cardFace)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.ink, lineWidth: 2)
            )

            Text("Tape tes potes dans l'ordre, du haut du podium vers le bas :")
                .font(Theme.Font.body(13))
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(contestants) { player in
                    rankingRow(player: player, session: session)
                }
            }
        }
    }

    private func rankingRow(player: Player, session: RankingSessionState) -> some View {
        let position = session.ranked.firstIndex(of: player.id)
        return Button {
            haptic(.light)
            handleToggleRanked(player.id)
        } label: {
            HStack(spacing: 12) {
                Text(position != nil ? "\(position! + 1)" : "-")
                    .font(Theme.Font.mono(14, weight: .bold))
                    .foregroundStyle(position != nil ? Theme.Color.background : Theme.Color.inkMuted)
                    .frame(width: 32, height: 32)
                    .background(position != nil ? Theme.Color.ink : Theme.Color.surface)
                    .clipShape(Circle())
                Text(player.name)
                    .font(Theme.Font.body(15, weight: .bold))
                    .foregroundStyle(Theme.Color.ink)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
        }
        .background(position != nil ? Theme.Color.neonSoft.opacity(0.35) : Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
        .accessibilityAddTraits(position != nil ? .isSelected : [])
    }

    private var returnCard: some View {
        // cardInk (fixe) sur toute la carte : fond cardFace direct, pas de
        // calque intermediaire, donc jamais ink/inkSecondary (thematisees).
        VStack(spacing: 12) {
            Image(systemName: "eye.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.Color.cardInk)
            Text("Podium verrouillé !")
                .font(Theme.Font.display(26))
                .foregroundStyle(Theme.Color.cardInk)
            Text("\(judge?.name ?? "Le juge"), repose le téléphone au centre de la table.")
                .font(Theme.Font.body(13))
                .foregroundStyle(Theme.Color.cardInk.opacity(0.7))
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

    private func guessingCard(session: RankingSessionState, round: RankingRound) -> some View {
        let groupGuessedRight = session.guessedId == round.question.id
        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Le podium de \(judge?.name ?? "")")
                    .font(Theme.Font.mono(10, weight: .bold))
                    .foregroundStyle(Theme.Color.inkMuted)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .center)
                ForEach(Array(session.ranked.enumerated()), id: \.element) { index, playerId in
                    HStack(spacing: 8) {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(medalColor(for: index))
                        Text("\(index + 1).")
                            .font(Theme.Font.mono(11))
                            .foregroundStyle(Theme.Color.inkMuted)
                        Text(playerName(playerId, session: session))
                            .font(Theme.Font.body(14, weight: .bold))
                            .foregroundStyle(Theme.Color.ink)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .stroke(Theme.Color.ink, lineWidth: 2)
            )

            Text(guessingHint(session: session, round: round, groupGuessedRight: groupGuessedRight))
                .font(Theme.Font.body(13))
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.updatesFrequently)

            VStack(spacing: 8) {
                ForEach(round.choices) { choice in
                    guessChoiceRow(choice: choice, session: session, round: round)
                }
            }
        }
    }

    private func guessChoiceRow(choice: RankingQuestion, session: RankingSessionState, round: RankingRound) -> some View {
        let isPicked = session.guessedId == choice.id
        let isReal = round.question.id == choice.id
        let isRevealing = session.phase == .reveal

        return Button {
            haptic(.medium)
            handleGuess(choice.id)
        } label: {
            HStack {
                Text(choice.text)
                    .font(Theme.Font.body(14, weight: .medium))
                    .foregroundStyle(Theme.Color.ink)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isRevealing && isReal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Color.success)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
        }
        .background(rowBackground(isRevealing: isRevealing, isPicked: isPicked, isReal: isReal))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
        .opacity(isRevealing && !isPicked && !isReal ? 0.5 : 1)
        .disabled(isRevealing)
    }

    private func rowBackground(isRevealing: Bool, isPicked: Bool, isReal: Bool) -> Color {
        guard isRevealing else { return Theme.Color.surface }
        if isReal { return Theme.Color.success.opacity(0.2) }
        if isPicked { return Theme.Color.cardRed.opacity(0.2) }
        return Theme.Color.surface
    }

    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return Theme.Color.premium
        case 1: return Theme.Color.inkMuted
        default: return Theme.Color.neonSoft
        }
    }

    private func playerName(_ id: String, session: RankingSessionState) -> String {
        session.players.first { $0.id == id }?.name ?? "?"
    }

    private func guessingHint(session: RankingSessionState, round: RankingRound, groupGuessedRight: Bool) -> String {
        guard session.phase == .reveal else {
            return "Quelle question secrète a produit ce classement ? Mettez-vous d'accord :"
        }
        if groupGuessedRight {
            return "Trouvé ! \(judge?.name ?? "Le juge") prend \(rankingJudgePenalty) pénalités."
        }
        return "Raté, c'était : « \(round.question.text) ». Tout le groupe prend \(rankingGroupPenalty) pénalité."
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        if let session {
            switch session.phase {
            case .handoff:
                primaryButton("Je suis \(judge?.name ?? "le juge"), j'ai le téléphone", action: handleStartJudging)
            case .judging:
                primaryButton(
                    "Valider mon podium",
                    isDisabled: session.ranked.count != contestants.count,
                    action: handleConfirmRanking
                )
            case .return:
                primaryButton("Le téléphone est au centre", action: handleStartGuessing)
            case .reveal:
                primaryButton("Manche suivante", systemImage: "arrow.clockwise", action: handleNextRound)
            case .guessing, .finished:
                EmptyView()
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
        // tileInk : fond neonDeep plein, clair dans les 2 themes.
        .foregroundStyle(Theme.Color.tileInk)
        .background(Theme.Color.neonDeep)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .opacity(isDisabled ? 0.5 : 1)
        .disabled(isDisabled)
    }

    // MARK: - Actions

    private func startSessionIfNeeded() {
        guard session == nil else { return }
        session = createRankingSession(questions: RankingContent.rankingQuestions, players: appState.activePlayers)
    }

    private func handleToggleRanked(_ playerId: String) {
        session = session.map { toggleRanked($0, playerId: playerId) }
    }

    private func handleGuess(_ questionId: String) {
        session = session.map { guessQuestion($0, questionId: questionId) }
    }

    private func handleStartJudging() {
        haptic(.light)
        session = session.map { startJudging($0) }
    }

    private func handleConfirmRanking() {
        haptic(.medium)
        session = session.map { confirmRanking($0) }
    }

    private func handleStartGuessing() {
        haptic(.light)
        session = session.map { startGuessing($0) }
    }

    private func handleNextRound() {
        haptic(.medium)
        session = session.map { nextRound($0) }
    }

    private func replaySession() {
        session = createRankingSession(questions: RankingContent.rankingQuestions, players: appState.activePlayers)
    }

    private func exitToHub() {
        appState.analytics.track(
            "session_completed",
            properties: ["mode": "ranking", "turns": String(session?.roundNumber ?? 0)]
        )
        appState.route = .hub
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// Local recap for Le Tableau d'Honneur: `Player.penalties` never gets
/// mutated by this mode, so the addition is built straight from
/// `RankingSessionState.penaltyCounts` instead of routing through the shared
/// `RecapView`.
private struct RankingRecapView: View {
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
                Text("Personne n'a craqué ce soir.")
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
                    Text("Nouveau tableau")
                        .font(Theme.Font.body(16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                // tileInk : fond neonDeep plein, clair dans les 2 themes.
                .foregroundStyle(Theme.Color.tileInk)
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
