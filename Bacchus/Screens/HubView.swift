import SwiftUI
import BacchusCore

struct HubView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var systemColorScheme
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    /// Thème effectif courant : suit l'OS quand la préférence est `.system`,
    /// comme `resolveTheme` côté web.
    private var isDark: Bool {
        appState.themeMode.colorScheme.map { $0 == .dark } ?? (systemColorScheme == .dark)
    }

    private var catalog: [PackCatalogEntry] {
        PackCatalog.loadAll()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                LazyVGrid(columns: columns, spacing: 12) {
                    borderlandTile
                    rouletteTile
                    tribunalTile
                    auctionTile
                    quizTile
                    rankingTile
                    wouldYouRatherTile

                    ForEach(Array(catalog.enumerated()), id: \.element.id) { offset, entry in
                        PackTile(
                            entry: entry,
                            // Continue la rotation "pop" après les 7 tuiles embarquées.
                            accent: Theme.Color.pop(offset + 7),
                            isUnlocked: !entry.premium || appState.entitlements.isPremium,
                            action: { appState.route = .prompt(packID: entry.id) },
                            onLockedTap: { appState.route = .paywall }
                        )
                    }
                }
            }
            .padding(20)
        }
    }

    private var header: some View {
        HStack {
            Text("MODES")
                .font(Theme.Font.display(28))
                .foregroundStyle(Theme.Color.ink)
            Spacer()
            if !appState.entitlements.isPremium {
                Button {
                    appState.route = .paywall
                } label: {
                    Text("Premium")
                        .font(Theme.Font.body(13, weight: .medium))
                        .foregroundStyle(Theme.Color.premium)
                }
                .frame(minHeight: 44)
                .accessibilityLabel("Découvrir Bacchus Premium")
            }
            Button {
                appState.route = .recap
            } label: {
                Text("Récap")
                    .font(Theme.Font.body(13, weight: .medium))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(minHeight: 44)

            themeToggle
            settingsButton
        }
        .padding(.top, 16)
    }

    private var settingsButton: some View {
        Button {
            appState.route = .settings
        } label: {
            Image(systemName: "gearshape.fill")
                .foregroundStyle(Theme.Color.inkSecondary)
        }
        .frame(width: 44, height: 44)
        .accessibilityLabel("Réglages")
    }

    /// Bascule discrète clair/sombre, place identique au web (`HubScreen.tsx`).
    /// Fige la préférence sur le résolu courant plutôt que de cycler
    /// `.system` : un appui = un aller-retour clair/sombre explicite.
    private var themeToggle: some View {
        Button {
            appState.themeMode = isDark ? .light : .dark
        } label: {
            Image(systemName: isDark ? "sun.max.fill" : "moon.fill")
                .foregroundStyle(Theme.Color.inkSecondary)
        }
        .frame(width: 44, height: 44)
        .accessibilityLabel(isDark ? "Passer en mode clair" : "Passer en mode sombre")
    }

    private var borderlandTile: some View {
        Button {
            appState.route = .borderland
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.pop(0))
                Spacer()
                Text("LE COUPE-GORGE")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.Color.ink)
                Text("Le jeu de cartes")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 140)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.neon.opacity(0.4), lineWidth: 1)
            )
        }
        .accessibilityLabel("Le Coupe-Gorge, le jeu de cartes")
    }

    private var rouletteTile: some View {
        Button {
            appState.route = .roulette
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.pop(1))
                Spacer()
                Text("LA ROUE DU DESTIN")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.Color.ink)
                Text("La roulette")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 140)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.neon.opacity(0.4), lineWidth: 1)
            )
        }
        .accessibilityLabel("La Roue du Destin, la roulette")
    }

    /// Le Pilori needs an author and at least one other player to accuse,
    /// so the trial pool never collapses back onto its own writer.
    private let tribunalMinPlayers = 3

    private var canPlayTribunal: Bool {
        appState.playerNames.count >= tribunalMinPlayers
    }

    private var tribunalTile: some View {
        Button {
            guard canPlayTribunal else { return }
            appState.route = .tribunal
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.pop(2))
                Spacer()
                Text("LE PILORI")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.Color.ink)
                Text("Le tribunal")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 140)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.neon.opacity(0.4), lineWidth: 1)
            )
            .opacity(canPlayTribunal ? 1 : 0.55)
            .overlay(alignment: .bottomTrailing) {
                if !canPlayTribunal {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(Theme.Color.inkMuted)
                        .padding(12)
                }
            }
        }
        .accessibilityLabel(
            canPlayTribunal
                ? "Le Pilori, le tribunal"
                : "Le Pilori, minimum \(tribunalMinPlayers) joueurs"
        )
    }

    private var auctionTile: some View {
        Button {
            appState.route = .auction
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.pop(3))
                Spacer()
                Text("LA CRIÉE")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.Color.ink)
                Text("L'enchère")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 140)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.neon.opacity(0.4), lineWidth: 1)
            )
        }
        .accessibilityLabel("La Criée, l'enchère")
    }

    private var quizTile: some View {
        Button {
            appState.route = .quiz
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "questionmark.diamond.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.pop(4))
                Spacer()
                Text("QUITTE OU TRINQUE")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.Color.ink)
                Text("Le quiz")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 140)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.neon.opacity(0.4), lineWidth: 1)
            )
        }
        .accessibilityLabel("Quitte ou Trinque, le quiz")
    }

    /// Le Tableau d'Honneur a besoin d'un juge et d'au moins trois candidats à
    /// classer pour que le podium ait un sens.
    private let rankingMinPlayers = 4

    private var canPlayRanking: Bool {
        appState.playerNames.count >= rankingMinPlayers
    }

    private var rankingTile: some View {
        Button {
            guard canPlayRanking else { return }
            appState.route = .ranking
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.pop(5))
                Spacer()
                Text("LE TABLEAU D'HONNEUR")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.Color.ink)
                Text("Le classement")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 140)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.neon.opacity(0.4), lineWidth: 1)
            )
            .opacity(canPlayRanking ? 1 : 0.55)
            .overlay(alignment: .bottomTrailing) {
                if !canPlayRanking {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(Theme.Color.inkMuted)
                        .padding(12)
                }
            }
        }
        .accessibilityLabel(
            canPlayRanking
                ? "Le Tableau d'Honneur, le classement"
                : "Le Tableau d'Honneur, minimum \(rankingMinPlayers) joueurs"
        )
    }
    private var wouldYouRatherTile: some View {
        Button {
            appState.route = .wouldYouRather
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.pop(6))
                Spacer()
                Text("TU PRÉFÈRES")
                    .font(Theme.Font.display(18))
                    .foregroundStyle(Theme.Color.ink)
                Text("Le dilemme")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 140)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.neon.opacity(0.4), lineWidth: 1)
            )
        }
        .accessibilityLabel("Tu préfères, le dilemme")
    }
}

private struct PackTile: View {
    let entry: PackCatalogEntry
    let accent: Color
    let isUnlocked: Bool
    let action: () -> Void
    let onLockedTap: () -> Void

    var body: some View {
        Button(action: isUnlocked ? action : onLockedTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: glyph(for: entry.mode))
                        .font(.system(size: 22))
                        .foregroundStyle(accent)
                    Spacer()
                    if entry.premium {
                        Text("PREMIUM")
                            .font(Theme.Font.mono(9, weight: .bold))
                            .foregroundStyle(Theme.Color.premium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Theme.Color.premium, lineWidth: 1)
                            )
                    }
                }
                Spacer()
                Text(entry.title)
                    .font(Theme.Font.body(14, weight: .medium))
                    .foregroundStyle(Theme.Color.ink)
                    .lineLimit(2)
                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(Theme.Font.body(11))
                        .foregroundStyle(Theme.Color.inkSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 140)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .opacity(isUnlocked ? 1 : 0.55)
            .overlay(alignment: .bottomTrailing) {
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.Color.inkMuted)
                        .padding(12)
                }
            }
        }
        .accessibilityLabel(isUnlocked ? entry.title : "\(entry.title), contenu premium verrouillé")
    }

    private func glyph(for mode: GameMode) -> String {
        switch mode {
        case .borderland: return "suit.spade.fill"
        case .picolo: return "flame.fill"
        case .truthOrDare: return "questionmark.circle.fill"
        case .neverHaveIEver: return "hand.raised.fill"
        case .whoAmong: return "person.2.fill"
        case .wouldYouRather: return "arrow.left.arrow.right"
        case .itsA10But: return "star.fill"
        case .sevenSeconds: return "timer"
        case .tribunal: return "scalemass.fill"
        case .roulette: return "circle.grid.cross.fill"
        case .auction: return "megaphone.fill"
        case .quiz: return "questionmark.diamond.fill"
        case .ranking: return "trophy.fill"
        }
    }
}
