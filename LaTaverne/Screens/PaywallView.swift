import SwiftUI
import LaTaverneCore

/// La Taverne Premium paywall. Reachable from the Hub header ("Premium") and from any locked
/// premium pack tile. Always shows the three advertised plans with their real price (transparent
/// pricing, no misleading free trial): monthly 4,99 €, annual 19,99 €, lifetime 34,99 €
/// highlighted as the best offer. Without a configured billing provider (guest mode,
/// `StubEntitlements`), the purchase button stays disabled with "Bientôt disponible" - never a
/// broken checkout.
struct PaywallView: View {
    @EnvironmentObject private var appState: AppState

    @State private var packages: [PremiumPackage] = []
    @State private var selectedPlan: PremiumPlan = .lifetime
    @State private var isLoadingPackages = true
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var statusMessage: String?

    private var purchaseReady: Bool {
        packages.contains { $0.id == selectedPlan }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            subtitle

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(PremiumPlan.catalogOrder, id: \.self) { plan in
                        planRow(for: plan)
                    }
                }
                .padding(.top, 4)

                Text("Abonnements : renouvellement automatique, résiliable à tout moment. "
                    + "À vie : paiement unique, sans abonnement.")
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
                Text("LA TAVERNE PREMIUM")
                    .font(Theme.Font.display(26))
                    .foregroundStyle(Theme.Color.ink)
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

    private func planRow(for plan: PremiumPlan) -> some View {
        let package = packages.first { $0.id == plan }
        let isSelected = selectedPlan == plan

        return Button {
            selectedPlan = plan
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(Theme.Font.body(15, weight: .bold))
                            .foregroundStyle(Theme.Color.ink)
                        if plan.isHighlighted {
                            Text("MEILLEURE OFFRE")
                                .font(Theme.Font.mono(9, weight: .bold))
                                .foregroundStyle(Theme.Color.premium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Theme.Color.premium, lineWidth: 1)
                                )
                        }
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
            .background(isSelected ? Theme.Color.premium.opacity(0.1) : Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .stroke(isSelected ? Theme.Color.premium : Theme.Color.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel("\(plan.title), \(package?.displayPrice ?? plan.fallbackPriceLabel), \(plan.note)")
    }

    private var purchaseButton: some View {
        Button {
            purchase()
        } label: {
            Text(isPurchasing ? "Achat en cours…" : (purchaseReady ? "Débloquer La Taverne Premium" : "Bientôt disponible"))
                .font(Theme.Font.body(16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .foregroundStyle(Theme.Color.ink)
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
        guard let package = packages.first(where: { $0.id == selectedPlan }) else { return }
        isPurchasing = true
        statusMessage = nil
        appState.analytics.track("purchase_started", properties: ["plan": selectedPlan.rawValue])
        Task {
            defer { isPurchasing = false }
            do {
                try await appState.entitlements.purchase(package)
                appState.analytics.track("purchase_completed", properties: ["plan": selectedPlan.rawValue])
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
