import SwiftUI
import BacchanaCore

/// Écran Réglages, accessible depuis l'icône engrenage du Hub. Consolide les contrôles
/// jusque-là éparpillés : apparence, premium, confidentialité, légal, à propos,
/// réinitialisation de la tablée. À parité avec `bacchana-site/src/components/screens/
/// SettingsScreen.tsx` (web) - ne réimplémente rien : chaque section délègue à `AppState`
/// ou à un écran existant (`PaywallView`).
///
/// Note de parité : le web propose aussi une section "Contenu" ("Mes règles",
/// `CustomRulesScreen.tsx`) ; l'app iOS n'a pas encore de moteur de règles personnalisées
/// (`BacchanaCore` n'expose aucun type dédié), donc cette section est omise plutôt que
/// simulée - à porter quand le module existera côté `BacchanaCore`.
///
/// Note légale : le web héberge des écrans dédiés (mentions légales, CGU/CGV, politique de
/// confidentialité) en navigation interne sans routes URL adressables ; en attendant leur
/// portage natif ou un déploiement de routes dédiées, cet écran renvoie vers le site
/// `bacchana.beloucif.com` (v0.15.0, actif), source unique de vérité pour ces textes.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL

    @State private var isRestoring = false
    @State private var restoreStatus: String?
    @State private var isConfirmingReset = false

    private static let legalURL = URL(string: "https://bacchana.beloucif.com")!

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    appearanceSection
                    premiumSection
                    privacySection
                    legalSection
                    aboutSection
                    resetSection
                }
                .padding(20)
            }
        }
        .confirmationDialog(
            "Réinitialiser la tablée ?",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("Réinitialiser", role: .destructive) {
                appState.resetTablee()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Les joueurs et la partie en cours seront effacés sur cet appareil. "
                + "Cette action est irréversible.")
        }
    }

    private var header: some View {
        HStack {
            Button {
                appState.route = .hub
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.Color.ink)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Retour au hub")

            Text("RÉGLAGES")
                .font(Theme.Font.display(22))
                .foregroundStyle(Theme.Color.ink)
                .accessibilityAddTraits(.isHeader)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
    }

    // MARK: - Apparence

    private var appearanceSection: some View {
        SettingsSection(title: "Apparence") {
            Picker("Thème", selection: $appState.themeMode) {
                Text("Système").tag(ThemeMode.system)
                Text("Clair").tag(ThemeMode.light)
                Text("Sombre").tag(ThemeMode.dark)
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)
            .accessibilityLabel("Thème de l'application")
        }
    }

    // MARK: - Premium

    private var premiumSection: some View {
        SettingsSection(title: "Premium") {
            HStack {
                Text("Statut")
                    .font(Theme.Font.body(15, weight: .bold))
                    .foregroundStyle(Theme.Color.ink)
                Spacer()
                Text(appState.entitlements.isPremium ? "PREMIUM ACTIF" : "INVITÉ")
                    .font(Theme.Font.mono(11, weight: .bold))
                    .foregroundStyle(appState.entitlements.isPremium ? Theme.Color.premium : Theme.Color.inkMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(
                        Capsule().stroke(
                            appState.entitlements.isPremium ? Theme.Color.premium : Theme.Color.border,
                            lineWidth: 1
                        )
                    )
            }
            .padding(16)
            .frame(minHeight: 52)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
            .accessibilityElement(children: .combine)

            if !appState.entitlements.isPremium {
                settingsButton(
                    title: "Débloquer le premium",
                    systemImage: "sparkles",
                    style: .primary
                ) {
                    appState.route = .paywall
                }
            }

            settingsButton(
                title: isRestoring ? "Restauration…" : "Restaurer mes achats",
                systemImage: "arrow.clockwise",
                style: .secondary,
                disabled: isRestoring
            ) {
                restore()
            }
            .accessibilityHint(
                appState.entitlements.isPremium
                    ? ""
                    : "En mode invité, aucun achat n'est encore configuré"
            )

            if let restoreStatus {
                Text(restoreStatus)
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.inkSecondary)
                    .accessibilityLabel(restoreStatus)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    private func restore() {
        isRestoring = true
        restoreStatus = nil
        Task {
            defer { isRestoring = false }
            do {
                try await appState.entitlements.restorePurchases()
                appState.analytics.track("restore_completed", properties: [:])
                restoreStatus = appState.entitlements.isPremium
                    ? "Premium restauré avec succès."
                    : "Aucun achat actif trouvé pour cet appareil."
            } catch {
                restoreStatus = "Bientôt disponible."
            }
        }
    }

    // MARK: - Confidentialité

    private var privacySection: some View {
        SettingsSection(title: "Confidentialité") {
            Toggle(isOn: $appState.analyticsConsent) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mesure d'audience")
                        .font(Theme.Font.body(15, weight: .bold))
                        .foregroundStyle(Theme.Color.ink)
                    Text("PostHog (instance UE), 13 mois maximum.")
                        .font(Theme.Font.body(12))
                        .foregroundStyle(Theme.Color.inkMuted)
                }
            }
            .tint(Theme.Color.neonDeep)
            .padding(16)
            .frame(minHeight: 52)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
            .accessibilityLabel("Activer la mesure d'audience")

            settingsButton(
                title: "Politique de confidentialité",
                systemImage: "doc.text",
                style: .ghost
            ) {
                openURL(Self.legalURL)
            }
        }
    }

    // MARK: - Légal

    private var legalSection: some View {
        SettingsSection(title: "Légal") {
            settingsButton(
                title: "Mentions légales, CGU/CGV",
                systemImage: "scroll",
                style: .ghost
            ) {
                openURL(Self.legalURL)
            }
            Text("Textes complets consultables sur bacchana.beloucif.com.")
                .font(Theme.Font.body(11))
                .foregroundStyle(Theme.Color.inkMuted)
        }
    }

    // MARK: - À propos

    private var aboutSection: some View {
        SettingsSection(title: "À propos") {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.Color.inkMuted)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bacchana")
                        .font(Theme.Font.display(16))
                        .foregroundStyle(Theme.Color.ink)
                    Text("Version \(appVersion)")
                        .font(Theme.Font.mono(11))
                        .foregroundStyle(Theme.Color.inkMuted)
                    Text("Éditeur : Adam Beloucif, nom commercial BLF Lab's")
                        .font(Theme.Font.body(12))
                        .foregroundStyle(Theme.Color.inkSecondary)
                }
            }
            .padding(16)
            .frame(minHeight: 52)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
            .accessibilityElement(children: .combine)
        }
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "-"
    }

    // MARK: - Réinitialiser

    private var resetSection: some View {
        SettingsSection(title: "Réinitialiser") {
            settingsButton(
                title: "Réinitialiser la tablée",
                systemImage: "arrow.counterclockwise",
                style: .destructive
            ) {
                isConfirmingReset = true
            }
            Text("Efface les joueurs et la partie en cours sur cet appareil. "
                + "Le statut premium et les achats ne sont jamais touchés.")
                .font(Theme.Font.body(11))
                .foregroundStyle(Theme.Color.inkMuted)
        }
    }

    // MARK: - Bouton générique

    private enum ButtonStyleKind: Equatable {
        case primary, secondary, ghost, destructive
    }

    private func settingsButton(
        title: String,
        systemImage: String,
        style: ButtonStyleKind,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(Theme.Font.body(14, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .foregroundStyle(foregroundColor(for: style))
        .background(backgroundColor(for: style))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .stroke(style == .destructive ? Theme.Color.danger.opacity(0.5) : .clear, lineWidth: 1)
        )
        .frame(minHeight: 44)
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
    }

    private func foregroundColor(for style: ButtonStyleKind) -> Color {
        switch style {
        // tileInk : fond neonDeep plein, clair dans les 2 themes.
        case .primary: return Theme.Color.tileInk
        case .secondary: return Theme.Color.ink
        case .ghost: return Theme.Color.inkSecondary
        // danger (thematisee), pas cardRed (fixe, reserve aux pips/cardFace) :
        // cardRed comme texte ici tombait a 2.38:1 en sombre.
        case .destructive: return Theme.Color.danger
        }
    }

    private func backgroundColor(for style: ButtonStyleKind) -> Color {
        switch style {
        case .primary: return Theme.Color.neonDeep
        case .secondary: return Theme.Color.surface
        case .ghost: return .clear
        case .destructive: return Theme.Color.danger.opacity(0.1)
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Theme.Font.display(13))
                .foregroundStyle(Theme.Color.inkMuted)
            content
        }
    }
}
