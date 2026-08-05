import SwiftUI
import UIKit
import LaTourneeCore

/// Le Pilori - "Le Procès". Chaque joueur écrit une accusation secrète (ou
/// la table joue avec celles de l'app). Les accusations sont tirées au
/// hasard : l'accusé se défend, puis la table vote à main levée. Mirrors
/// `la-taverne/src/components/screens/TribunalScreen.tsx`.
///
/// The mode keeps its own local `penaltyCounts` via `TribunalSession` and
/// never touches `Player.penalties`, so the finished state renders its own
/// recap instead of the shared `RecapView`.
struct TribunalView: View {
    @EnvironmentObject private var appState: AppState

    @State private var session: TribunalSession?
    @State private var phase: TribunalPhase = .intro
    @State private var writerIndex = 0
    @State private var draft = ""
    @State private var collectedPool: [TribunalAccusation] = []
    @State private var votesGuilty = 0
    @State private var votesInnocent = 0

    private var activePlayers: [Player] {
        session?.players ?? appState.activePlayers.filter(\.active)
    }

    private var writer: Player? {
        guard writerIndex < activePlayers.count else { return nil }
        return activePlayers[writerIndex]
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
            .accessibilityLabel("Quitter le procès et revenir à l'accueil")

            Spacer()

            VStack(spacing: 2) {
                Text("LE PILORI")
                    .font(Theme.Font.body(13, weight: .medium))
                    .foregroundStyle(Theme.Color.inkSecondary)
                if let accused = session?.accused, phase == .defense || phase == .vote {
                    Text(accused.name)
                        .font(Theme.Font.display(20))
                        .foregroundStyle(Theme.Color.ink)
                }
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .intro:
            introContent
        case .collectHandoff:
            handoffContent
        case .collectWrite:
            writeContent
        case .defense, .vote:
            trialContent
        case .finished:
            TribunalRecapView(
                players: activePlayers,
                penaltyCounts: session?.penaltyCounts ?? [:],
                onReplay: replaySession,
                onQuit: exitToHub
            )
        }
    }

    private var introContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.Color.neon)
            Text("La cour est ouverte")
                .font(Theme.Font.display(24))
                .foregroundStyle(Theme.Color.ink)
            Text("Chacun écrit une accusation secrète contre la table… ou vous laissez l'app fournir les chefs d'accusation.")
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var handoffContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.Color.ink)
            if let writer {
                Text("Accusation secrète \(writerIndex + 1)/\(activePlayers.count)")
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.Color.inkSecondary)
                Text("Passe le téléphone à \(writer.name)")
                    .font(Theme.Font.display(22))
                    .foregroundStyle(Theme.Color.ink)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.Color.neonSoft.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
    }

    private var writeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let writer {
                Text("\(writer.name), accuse qui tu veux - ton accusation restera anonyme.")
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.Color.inkSecondary)
                    .multilineTextAlignment(.leading)
            }
            TextEditor(text: $draft)
                .font(Theme.Font.body(15))
                .foregroundStyle(Theme.Color.ink)
                .scrollContentBackground(.hidden)
                .frame(height: 120)
                .padding(8)
                .background(Theme.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.control)
                        .stroke(Theme.Color.ink, lineWidth: 2)
                )
                .onChange(of: draft) { _, newValue in
                    if newValue.count > 200 {
                        draft = String(newValue.prefix(200))
                    }
                }
                .accessibilityLabel("Ton accusation")

            Text("\(draft.count)/200")
                .font(Theme.Font.mono(11))
                .foregroundStyle(Theme.Color.inkMuted)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var trialContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.Color.cardRed)
                Text(session?.chargeText ?? "")
                    .font(Theme.Font.body(17))
                    .foregroundStyle(Theme.Color.cardInk)
                    .multilineTextAlignment(.center)
                if session?.current?.authorID != nil {
                    Text("accusation anonyme de la table")
                        .font(Theme.Font.mono(10, weight: .bold))
                        // cardInk (fixe) attenue : pose directement sur cardFace.
                        .foregroundStyle(Theme.Color.cardInk.opacity(0.7))
                        .textCase(.uppercase)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Theme.Color.cardFace)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.ink, lineWidth: 2)
            )
            .accessibilityElement(children: .combine)

            if phase == .defense, let accused = session?.accused {
                Text("\(accused.name) a 30 secondes pour se défendre. Écoutez… puis votez.")
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.updatesFrequently)
            }

            if phase == .vote {
                voteControls
            }
        }
    }

    private var voteControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                voteButton(
                    label: "Coupable",
                    count: votesGuilty,
                    systemImage: "hand.thumbsdown.fill",
                    tint: Theme.Color.neon
                ) {
                    votesGuilty += 1
                }

                voteButton(
                    label: "Non coupable",
                    count: votesInnocent,
                    systemImage: "hand.thumbsup.fill",
                    tint: Theme.Color.success
                ) {
                    votesInnocent += 1
                }
            }

            if let verdict = session?.verdict {
                Text(verdict == .guilty ? "Coupable - 1 pénalité" : "Non coupable - libéré")
                    .font(Theme.Font.display(20))
                    .foregroundStyle(verdict == .guilty ? Theme.Color.neon : Theme.Color.success)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    private func voteButton(
        label: String,
        count: Int,
        systemImage: String,
        tint: SwiftUI.Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            haptic(.light)
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Text("\(count)")
                    .font(Theme.Font.mono(18, weight: .bold))
                    .foregroundStyle(Theme.Color.ink)
                Text(label.uppercased())
                    .font(Theme.Font.mono(10, weight: .bold))
                    .foregroundStyle(Theme.Color.inkMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
        }
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
        .disabled(session?.verdict != nil)
        .opacity(session?.verdict != nil ? 0.4 : 1)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .intro:
            VStack(spacing: 12) {
                primaryButton("On écrit nos accusations", systemImage: "pencil.line", action: handleStartCollect)
                secondaryButton("Accusations de l'app", systemImage: "sparkles", action: handleUseAppCharges)
            }
        case .collectHandoff:
            if let writer {
                primaryButton("C'est moi, \(writer.name)") {
                    haptic(.light)
                    phase = .collectWrite
                }
            }
        case .collectWrite:
            primaryButton("Accusation déposée", isDisabled: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                handleSubmitAccusation()
            }
        case .defense:
            primaryButton("Passer au vote", systemImage: "scalemass.fill") {
                haptic(.light)
                phase = .vote
            }
        case .vote:
            if session?.verdict == nil {
                primaryButton("Verdict", systemImage: "scalemass.fill", action: handleVerdict)
            } else {
                VStack(spacing: 12) {
                    primaryButton(
                        (session?.pool.isEmpty ?? true) ? "Nouveau procès" : "Procès suivant",
                        systemImage: "arrow.counterclockwise",
                        action: handleNewTrial
                    )
                    secondaryButton("Terminer et voir l'addition", systemImage: "doc.text.fill", action: finishSession)
                }
            }
        case .finished:
            EmptyView()
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
        session = TribunalSession(players: appState.activePlayers)
    }

    private func handleUseAppCharges() {
        haptic(.light)
        session?.startTrial(from: [])
        votesGuilty = 0
        votesInnocent = 0
        phase = .defense
    }

    private func handleStartCollect() {
        haptic(.light)
        writerIndex = 0
        draft = ""
        collectedPool = []
        phase = .collectHandoff
    }

    private func handleSubmitAccusation() {
        guard let writer else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        haptic(.light)

        collectedPool.append(TribunalAccusation(text: text, authorID: writer.id))
        draft = ""

        if writerIndex + 1 < activePlayers.count {
            writerIndex += 1
            phase = .collectHandoff
        } else {
            session?.startTrial(from: collectedPool)
            votesGuilty = 0
            votesInnocent = 0
            phase = .defense
        }
    }

    private func handleVerdict() {
        haptic(.medium)
        session?.resolveVerdict(votesGuilty: votesGuilty, votesInnocent: votesInnocent)
    }

    private func handleNewTrial() {
        haptic(.light)
        session?.startTrial(from: session?.pool ?? [])
        votesGuilty = 0
        votesInnocent = 0
        phase = .defense
    }

    private func finishSession() {
        haptic(.medium)
        phase = .finished
    }

    private func replaySession() {
        session = TribunalSession(players: appState.activePlayers)
        writerIndex = 0
        draft = ""
        collectedPool = []
        votesGuilty = 0
        votesInnocent = 0
        phase = .intro
    }

    private func exitToHub() {
        appState.analytics.track(
            "session_completed",
            properties: ["mode": "tribunal", "turns": String(session?.trialsPlayed ?? 0)]
        )
        appState.route = .hub
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// Local recap for Le Pilori: `Player.penalties` never gets mutated by this
/// mode, so the addition is built straight from `TribunalSession.penaltyCounts`
/// instead of routing through the shared `RecapView`.
private struct TribunalRecapView: View {
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
            Text("VERDICT FINAL")
                .font(Theme.Font.display(26))
                .foregroundStyle(Theme.Color.ink)

            if ranked.allSatisfy({ $0.count == 0 }) {
                Text("Personne n'a été reconnu coupable ce soir.")
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
                    Text("Nouveau procès")
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
