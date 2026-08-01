import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var newPlayerName: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("BLACKOUT")
                    .font(Theme.Font.display(48))
                    .foregroundStyle(Theme.Color.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("52 cartes - 4 règles - 0 pitié.")
                    .font(Theme.Font.mono(15))
                    .foregroundStyle(Theme.Color.neon)
            }
            .padding(.top, 32)

            Text("Inscription à l'arène")
                .font(Theme.Font.body(13, weight: .medium))
                .foregroundStyle(Theme.Color.inkSecondary)
                .textCase(.uppercase)

            playerList

            addPlayerField

            Spacer()

            Button(action: startGame) {
                Text("Entrer dans l'arène")
                    .font(Theme.Font.body(17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .foregroundStyle(Theme.Color.ink)
            .background(appState.canStart ? Theme.Color.neonDeep : Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
            .disabled(!appState.canStart)
            .accessibilityHint(appState.canStart ? "" : "Ajoute au moins deux joueurs pour commencer")

            Text("Jouez responsable. Réservé aux adultes.")
                .font(Theme.Font.mono(11))
                .foregroundStyle(Theme.Color.inkMuted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
    }

    private var playerList: some View {
        VStack(spacing: 12) {
            ForEach(Array(appState.playerNames.enumerated()), id: \.offset) { index, name in
                HStack {
                    Text(name)
                        .font(Theme.Font.body(16))
                        .foregroundStyle(Theme.Color.ink)
                    Spacer()
                    Button {
                        appState.playerNames.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.Color.inkMuted)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("Retirer \(name)")
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(Theme.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
            }
        }
    }

    private var addPlayerField: some View {
        HStack {
            TextField("Nom du joueur", text: $newPlayerName)
                .font(Theme.Font.body(16))
                .foregroundStyle(Theme.Color.ink)
                .focused($fieldFocused)
                .submitLabel(.done)
                .onSubmit(addPlayer)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(Theme.Color.backgroundRaised)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))

            Button(action: addPlayer) {
                Image(systemName: "plus")
                    .foregroundStyle(Theme.Color.ink)
                    .frame(width: 44, height: 44)
                    .background(Theme.Color.neonDeep)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
            }
            .accessibilityLabel("Ajouter le joueur")
            .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func addPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        appState.playerNames.append(trimmed)
        newPlayerName = ""
        fieldFocused = true
    }

    private func startGame() {
        guard appState.canStart else { return }
        appState.startSession()
        appState.route = .hub
    }
}
