import SwiftUI
import BacchanaCore

/// Bacchana Premium paywall. Reachable from the Hub header ("Premium") and from any locked
/// premium pack tile. Shows ONE offer with its real store price - a single payment at 12,99 €,
/// no subscription and no misleading free trial. Without a configured billing provider (guest
/// mode, `StubEntitlements`), the purchase button stays disabled with "Bientôt disponible" -
/// never a broken checkout.
///
/// There is no plan picker, and that absence is the argument: the screen has nothing to
/// arbitrate because there is nothing to arbitrate. It used to offer three plans, two of them
/// subscriptions, which contradicted the one thing the product promises.
struct PaywallView: View {
    @EnvironmentObject private var appState: AppState

    @State private var packages: [PremiumPackage] = []
    @State private var isLoadingPackages = true
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var statusMessage: String?

    /// The only plan there is. No `@State`: a picker with one option is a screen asking a
    /// question it already knows the answer to.
    private let plan: PremiumPlan = .lifetime

    private var purchaseReady: Bool {
        packages.contains { $0.id == plan }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            subtitle

            ScrollView {
                planRow(for: plan)
                    .padding(.top, 4)

                Text("Paiement unique. Aucun abonnement, aucun renouvellement, "
                    + "aucun essai gratuit.")
                    .font(Theme.Font.body(11))
                    .foregroundStyle(Theme.Color.inkMuted)
                    .padding(.top, 12)

                if let statusMessage {
                    Text(statusMessage)
                        .font(Theme.Font.body(12, weight: .medium))
                        .foregroundStyle(Theme.Color.warning)
                        .padding(.top, 8)
                }
            }

            Spacer(minLength: 0)

            purchaseButton
            restoreButton
        }
        .padding(20)
        .task {
            appState.analytics.track("paywall_shown", properties: [:])
            isLoadingPackages = true
            packages = await appState.entitlements.fetchPackages()
            isLoadingPackages = false
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BACCHANA PREMIUM")
                    .font(Theme.Font.display(26))
                    // Accent orange, pas l'encre : AA vérifié (`orangeInk`, cf. Theme.swift)
                    // dans les deux thèmes, contrairement à l'encre qui se fondait avec la
                    // bordure/le fond au même ton en clair comme en sombre.
                    .foregroundStyle(Theme.Color.orangeInk)
                Text("Débloque tous les packs premium de la collection")
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            Spacer()
            Button {
                appState.analytics.track("paywall_dismissed", properties: [:])
                appState.route = .hub
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.Color.inkMuted)
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("Fermer")
        }
        .padding(.top, 16)
    }

    private var subtitle: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .foregroundStyle(Theme.Color.premium)
            Text(isLoadingPackages ? "Chargement des tarifs…" : "Prix TTC, sans essai gratuit")
                .font(Theme.Font.mono(11))
                .foregroundStyle(Theme.Color.inkMuted)
        }
    }

    /// L'offre, affichée et non proposée au choix. Plus de `Button` : un élément qui réagit au
    /// doigt promet une alternative, et il n'y en a pas.
    private func planRow(for plan: PremiumPlan) -> some View {
        let package = packages.first { $0.id == plan }

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(plan.title)
                        .font(Theme.Font.body(15, weight: .bold))
                        .foregroundStyle(Theme.Color.ink)
                    Text("SEULE OFFRE")
                        .font(Theme.Font.mono(9, weight: .bold))
                        .foregroundStyle(Theme.Color.premium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Theme.Color.premium, lineWidth: 1)
                        )
                }
                Text(plan.note)
                    .font(Theme.Font.body(11))
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            Spacer()
            Text(package?.displayPrice ?? plan.fallbackPriceLabel)
                .font(Theme.Font.mono(17, weight: .bold))
                .foregroundStyle(Theme.Color.ink)
        }
        .padding(16)
        .frame(minHeight: 56)
        .background(Theme.Color.premium.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .stroke(Theme.Color.premium, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.title), \(package?.displayPrice ?? plan.fallbackPriceLabel), \(plan.note)")
    }

    private var purchaseButton: some View {
        Button {
            purchase()
        } label: {
            Text(isPurchasing ? "Achat en cours…" : (purchaseReady ? "Débloquer Bacchana Premium" : "Bientôt disponible"))
                .font(Theme.Font.body(16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        // tileInk sur neonDeep (plein, clair dans les 2 themes) ; ink sur
        // surface (thematisee) tant que l'achat n'est pas pret.
        .foregroundStyle(purchaseReady ? Theme.Color.tileInk : Theme.Color.ink)
        .background(purchaseReady ? Theme.Color.neonDeep : Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .disabled(!purchaseReady || isPurchasing)
        .accessibilityHint(purchaseReady ? "" : "Achat pas encore disponible")
    }

    private var restoreButton: some View {
        Button {
            restore()
        } label: {
            Text(isRestoring ? "Restauration…" : "Restaurer mes achats")
                .font(Theme.Font.body(13, weight: .medium))
                .foregroundStyle(Theme.Color.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .disabled(isRestoring)
    }

    private func purchase() {
        guard let package = packages.first(where: { $0.id == plan }) else { return }
        isPurchasing = true
        statusMessage = nil
        appState.analytics.track("purchase_started", properties: ["plan": plan.rawValue])
        Task {
            defer { isPurchasing = false }
            do {
                try await appState.entitlements.purchase(package)
                appState.analytics.track("purchase_completed", properties: ["plan": plan.rawValue])
                if appState.entitlements.isPremium {
                    appState.route = .hub
                }
            } catch {
                statusMessage = "L'achat n'a pas abouti. Réessaie plus tard."
            }
        }
    }

    private func restore() {
        isRestoring = true
        statusMessage = nil
        Task {
            defer { isRestoring = false }
            do {
                try await appState.entitlements.restorePurchases()
                appState.analytics.track("restore_completed", properties: [:])
                if appState.entitlements.isPremium {
                    appState.route = .hub
                } else {
                    statusMessage = "Aucun achat à restaurer sur ce compte."
                }
            } catch {
                statusMessage = "La restauration a échoué. Réessaie plus tard."
            }
        }
    }
}
