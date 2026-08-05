import SwiftUI
import BacchusCore

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var newPlayerName: String = ""
    @FocusState private var fieldFocused: Bool
    /// Un seul panneau genre/statut ouvert à la fois - reste compact, jamais imposé.
    @State private var expandedIndex: Int?

    /// Wraps an option's value + label. `Identifiable` (rather than a bare
    /// tuple) so `ForEach` gets a real key path - Swift key paths cannot
    /// address labeled tuple elements.
    private struct Option<Value: Equatable>: Identifiable {
        let value: Value
        let label: String
        var id: String { label }
    }

    private static let genderOptions: [Option<Player.Gender>] = [
        Option(value: .masculine, label: "Homme"),
        Option(value: .feminine, label: "Femme"),
        Option(value: .other, label: "Autre"),
    ]

    private static let relationshipOptions: [Option<Player.Relationship>] = [
        Option(value: .single, label: "Célibataire"),
        Option(value: .couple, label: "En couple"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("BACCHUS")
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
            // tileInk sur neonDeep (plein, clair dans les 2 themes) ; ink sur
            // surface (thematisee) quand desactive.
            .foregroundStyle(appState.canStart ? Theme.Color.tileInk : Theme.Color.ink)
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
        VStack(spacing: 8) {
            ForEach(Array(appState.playerNames.enumerated()), id: \.offset) { index, name in
                playerRow(index: index, name: name)
            }
        }
    }

    private func playerRow(index: Int, name: String) -> some View {
        let attributes = appState.attributes(at: index)
        let isExpanded = expandedIndex == index
        let hasAttributes = !attributes.isEmpty

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(Theme.Font.body(16))
                    .foregroundStyle(Theme.Color.ink)
                Spacer()

                // Genre + statut - facultatif, replié par défaut.
                Button {
                    expandedIndex = isExpanded ? nil : index
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(isExpanded || hasAttributes ? Theme.Color.orangeInk : Theme.Color.inkMuted)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Genre et statut de \(name), facultatif")

                Button {
                    appState.removePlayerName(at: index)
                    if expandedIndex == index { expandedIndex = nil }
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

            if isExpanded {
                attributesPanel(index: index, attributes: attributes, name: name)
            }
        }
    }

    private func attributesPanel(index: Int, attributes: PlayerAttributes, name: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            optionGroup(
                label: "Genre de \(name)",
                options: Self.genderOptions,
                selected: attributes.gender,
                onSelect: { value in
                    var updated = attributes
                    updated.gender = attributes.gender == value ? nil : value
                    appState.setAttributes(updated, at: index)
                }
            )
            optionGroup(
                label: "Statut relationnel de \(name)",
                options: Self.relationshipOptions,
                selected: attributes.relationship,
                onSelect: { value in
                    var updated = attributes
                    updated.relationship = attributes.relationship == value ? nil : value
                    appState.setAttributes(updated, at: index)
                }
            )
        }
        .padding(.leading, 16)
    }

    private func optionGroup<Value: Equatable>(
        label: String,
        options: [Option<Value>],
        selected: Value?,
        onSelect: @escaping (Value) -> Void
    ) -> some View {
        FlowWrap(spacing: 6) {
            ForEach(options) { option in
                let isSelected = selected == option.value
                Button {
                    onSelect(option.value)
                } label: {
                    Text(option.label)
                        .font(Theme.Font.body(12, weight: .semibold))
                        .padding(.horizontal, 12)
                }
                .frame(minHeight: 44)
                .background(isSelected ? Theme.Color.neon.opacity(0.15) : Theme.Color.backgroundRaised)
                .foregroundStyle(isSelected ? Theme.Color.orangeInk : Theme.Color.inkMuted)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Theme.Color.neon : Theme.Color.border, lineWidth: 1)
                )
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .accessibilityLabel("\(option.label), \(label)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
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
                    // tileInk : fond neonDeep plein, clair dans les 2 themes.
                    .foregroundStyle(Theme.Color.tileInk)
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
        appState.addPlayerName(trimmed)
        newPlayerName = ""
        fieldFocused = true
    }

    private func startGame() {
        guard appState.canStart else { return }
        appState.startSession()
        appState.route = .hub
    }
}

/// Minimal flow layout wrapping pill buttons onto multiple lines, used for
/// the gender/relationship option groups. `Layout` (iOS 16+) keeps this a
/// pure SwiftUI primitive with no third-party dependency.
private struct FlowWrap: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : rowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: origin, proposal: .unspecified)
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
