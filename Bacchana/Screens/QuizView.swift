import SwiftUI
import UIKit
import BacchanaCore

/// Quitte ou Double - quiz de culture générale à cagnotte. Bonne réponse :
/// les points rejoignent la cagnotte du joueur, qui choisit ensuite entre
/// cumuler (tout risquer) ou distribuer. Mauvaise réponse : il prend sa
/// cagnotte + les points en jeu en pénalités. Mirrors
/// `bacchana-site/src/components/screens/QuizScreen.tsx`.
///
/// The mode keeps its own local `penaltyCounts` via `QuizSessionState` and
/// never touches `Player.penalties`, so the finished state renders its own
/// recap instead of the shared `RecapView`.
struct QuizView: View {
    @EnvironmentObject private var appState: AppState

    @State private var session: QuizSessionState?
    @State private var answerShown = false

    private var activePlayers: [Player] {
        session?.players ?? appState.activePlayers.filter(\.active)
    }

    private var currentPlayer: Player? {
        session.flatMap { getCurrentQuizPlayer($0) }
    }

    private var pot: Int {
        guard let session, let currentPlayer else { return 0 }
        return session.pots[currentPlayer.id] ?? 0
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
                .accessibilityLabel("Quitter le quiz et revenir à l'accueil")

                Spacer()

                VStack(spacing: 2) {
                    Text("QUITTE OU DOUBLE")
                        .font(Theme.Font.body(13, weight: .medium))
                        .foregroundStyle(Theme.Color.inkSecondary)
                    if let currentPlayer, session?.phase != .finished {
                        Text(currentPlayer.name)
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
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                        Text("Cagnotte : \(pot)")
                            .font(Theme.Font.mono(12, weight: .bold))
                    }
                    .foregroundStyle(Theme.Color.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Color.neonSoft.opacity(0.35))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.Color.ink, lineWidth: 2))

                    Text("\(session.turnNumber)/\(session.turnNumber + session.queue.count)")
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
            case .question:
                if let question = session.currentQuestion {
                    questionCard(session: session, question: question)
                }
            case .choice:
                choiceCard
            case .finished:
                QuizRecapView(
                    players: activePlayers,
                    penaltyCounts: session.penaltyCounts,
                    onReplay: replaySession,
                    onQuit: exitToHub
                )
            }
        }
    }

    private func questionCard(session: QuizSessionState, question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                // cardInk, pas ink : ces badges sont nichés dans questionCard,
                // dont le fond est cardFace (fixe blanc), même tinté à 25-30%.
                Text(question.category.label.uppercased())
                    .font(Theme.Font.mono(10, weight: .bold))
                    .foregroundStyle(Theme.Color.cardInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.Color.neonSoft.opacity(0.3))
                    .clipShape(Capsule())

                Text("\(session.currentPoints) point\(session.currentPoints > 1 ? "s" : "") en jeu")
                    .font(Theme.Font.mono(10, weight: .bold))
                    .foregroundStyle(Theme.Color.cardInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.Color.premium.opacity(0.25))
                    .clipShape(Capsule())
            }

            Text(question.question)
                .font(Theme.Font.body(17, weight: .medium))
                .foregroundStyle(Theme.Color.cardInk)
                .multilineTextAlignment(.center)

            if answerShown {
                Text(question.answer)
                    .font(Theme.Font.body(15))
                    .foregroundStyle(Theme.Color.cardInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Color.success.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
                    .accessibilityAddTraits(.updatesFrequently)
            } else {
                Button {
                    haptic(.light)
                    answerShown = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                        Text("Voir la réponse")
                            .font(Theme.Font.body(14, weight: .bold))
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 16)
                }
                .foregroundStyle(Theme.Color.ink)
                .background(Theme.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.control)
                        .stroke(Theme.Color.ink, lineWidth: 2)
                )
            }

            if let lastOutcome = session.lastOutcome {
                Text(outcomeText(lastOutcome))
                    .font(Theme.Font.mono(11, weight: .bold))
                    // cardInk (fixe) attenue : pose directement sur cardFace.
                    .foregroundStyle(Theme.Color.cardInk.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .textCase(.uppercase)
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

    private var choiceCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 30))
                .foregroundStyle(Theme.Color.ink)
            Text("Bien joué !")
                .font(Theme.Font.display(22))
                .foregroundStyle(Theme.Color.ink)
            Text("Ta cagnotte monte à \(pot). Tu la laisses grossir… ou tu la distribues maintenant ?")
                .font(Theme.Font.body(14))
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

    private func outcomeText(_ outcome: QuizOutcome) -> String {
        let name = activePlayers.first { $0.id == outcome.playerId }?.name ?? ""
        let plural = outcome.amount > 1 ? "s" : ""
        switch outcome.kind {
        case .busted:
            return "\(name) a craqué : \(outcome.amount) pénalité\(plural) !"
        case .banked:
            return "\(name) distribue \(outcome.amount) pénalité\(plural) à la table !"
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        if let session {
            switch session.phase {
            case .question:
                HStack(spacing: 12) {
                    secondaryButton("Raté", systemImage: "xmark", action: handleWrong)
                    primaryButton("Bonne réponse", systemImage: "checkmark", action: handleCorrect)
                }
            case .choice:
                VStack(spacing: 12) {
                    primaryButton("Je distribue mes \(pot) point\(pot > 1 ? "s" : "")", systemImage: "arrow.triangle.branch", action: handleDistribute)
                    secondaryButton("Je cumule (quitte ou double)", systemImage: "flame.fill", action: handleKeep)
                }
            case .finished:
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

    private func startSessionIfNeeded() {
        guard session == nil else { return }
        session = createQuizSession(questions: QuizContent.quizQuestions, players: appState.activePlayers)
    }

    private func handleCorrect() {
        haptic(.light)
        session = session.map { answerCorrect($0) }
        answerShown = false
    }

    private func handleWrong() {
        haptic(.medium)
        session = session.map { answerWrong($0) }
        answerShown = false
    }

    private func handleDistribute() {
        haptic(.medium)
        session = session.map { distributePot($0) }
    }

    private func handleKeep() {
        haptic(.light)
        session = session.map { keepPot($0) }
    }

    private func replaySession() {
        session = createQuizSession(questions: QuizContent.quizQuestions, players: appState.activePlayers)
        answerShown = false
    }

    private func exitToHub() {
        appState.analytics.track(
            "session_completed",
            properties: ["mode": "quiz", "turns": String(session?.turnNumber ?? 0)]
        )
        appState.route = .hub
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// Local recap for Quitte ou Double: `Player.penalties` never gets mutated
/// by this mode, so the addition is built straight from
/// `QuizSessionState.penaltyCounts` instead of routing through the shared
/// `RecapView`.
private struct QuizRecapView: View {
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
                    Text("Nouveau quiz")
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
