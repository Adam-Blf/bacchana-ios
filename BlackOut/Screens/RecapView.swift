import SwiftUI
import BlackOutCore

struct RecapView: View {
    @EnvironmentObject private var appState: AppState

    private var rankedPlayers: [Player] {
        appState.activePlayers.sorted {
            totalPenalties($0) > totalPenalties($1)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            if rankedPlayers.isEmpty {
                Spacer()
                Text("Pas encore de partie jouée.")
                    .font(Theme.Font.body(15))
                    .foregroundStyle(Theme.Color.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                            playerRow(rank: index + 1, player: player)
                        }
                    }
                }
            }

            Button {
                appState.route = .hub
            } label: {
                Text("Retour au hub")
                    .font(Theme.Font.body(16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .foregroundStyle(Theme.Color.ink)
            .background(Theme.Color.neonDeep)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        }
        .padding(20)
    }

    private var header: some View {
        Text("PODIUM")
            .font(Theme.Font.display(32))
            .foregroundStyle(Theme.Color.ink)
            .padding(.top, 16)
    }

    private func totalPenalties(_ player: Player) -> Int {
        player.penaltiesStandard + player.penaltiesMajor
    }

    private func playerRow(rank: Int, player: Player) -> some View {
        HStack(spacing: 16) {
            Text("\(rank)")
                .font(Theme.Font.mono(20, weight: .bold))
                .foregroundStyle(rank == 1 ? Theme.Color.premium : Theme.Color.inkSecondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(Theme.Font.body(16, weight: .medium))
                    .foregroundStyle(Theme.Color.ink)
                Text("\(player.penaltiesStandard) pénalités - \(player.penaltiesMajor) majeures")
                    .font(Theme.Font.mono(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .accessibilityElement(children: .combine)
    }
}
