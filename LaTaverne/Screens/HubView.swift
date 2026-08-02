import SwiftUI
import LaTaverneCore

struct HubView: View {
    @EnvironmentObject private var appState: AppState
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var catalog: [PackCatalogEntry] {
        PackCatalog.loadAll()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                LazyVGrid(columns: columns, spacing: 12) {
                    borderlandTile

                    ForEach(catalog) { entry in
                        PackTile(entry: entry, isUnlocked: !entry.premium || appState.entitlements.isPremium) {
                            appState.route = .prompt(packID: entry.id)
                        }
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
            Button {
                appState.route = .recap
            } label: {
                Text("Récap")
                    .font(Theme.Font.body(13, weight: .medium))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .frame(minHeight: 44)
        }
        .padding(.top, 16)
    }

    private var borderlandTile: some View {
        Button {
            appState.route = .borderland
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.neon)
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
}

private struct PackTile: View {
    let entry: PackCatalogEntry
    let isUnlocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: isUnlocked ? action : {}) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: glyph(for: entry.mode))
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.Color.neon)
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
        }
    }
}
