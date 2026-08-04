import Foundation

/// Premium plan identifiers, matching the RevenueCat / App Store Connect product IDs and the
/// web catalog (`la-taverne/src/lib/billing.ts`). Kept in `MeskovaCore` so the pricing/plan
/// logic stays pure and unit-testable without pulling in any billing SDK.
public enum PremiumPlan: String, Sendable, CaseIterable {
    case monthly = "premium_monthly"
    case yearly = "premium_yearly"
    case lifetime = "premium_lifetime"

    /// Display order on the paywall: monthly, annual, then lifetime highlighted last.
    public static let catalogOrder: [PremiumPlan] = [.monthly, .yearly, .lifetime]

    /// Advertised price shown before a real store price is available (guest mode, offline, or
    /// offerings not yet loaded). Mirrors the RevenueCat dashboard configuration.
    public var fallbackPriceLabel: String {
        switch self {
        case .monthly: return "4,99 €"
        case .yearly: return "19,99 €"
        case .lifetime: return "34,99 €"
        }
    }

    public var title: String {
        switch self {
        case .monthly: return "Mensuel"
        case .yearly: return "Annuel"
        case .lifetime: return "À vie"
        }
    }

    public var note: String {
        switch self {
        case .monthly, .yearly:
            return "Renouvellement automatique, résiliable à tout moment"
        case .lifetime:
            return "Paiement unique, à toi pour toujours"
        }
    }

    /// The lifetime plan is the highlighted "best offer": one payment, no recurring billing,
    /// Meskova's differentiator against subscription-only competitors.
    public var isHighlighted: Bool { self == .lifetime }
}

/// A purchasable premium package as surfaced to the UI, decoupled from the underlying billing
/// SDK (RevenueCat) so views and tests never import it directly.
public struct PremiumPackage: Identifiable, Equatable, Sendable {
    public let id: PremiumPlan
    /// Real store price string once fetched from the billing provider; `nil` falls back to
    /// `PremiumPlan.fallbackPriceLabel`.
    public let priceLabel: String?

    public init(id: PremiumPlan, priceLabel: String?) {
        self.id = id
        self.priceLabel = priceLabel
    }

    /// Price to display: the real store price when known, otherwise the advertised default.
    public var displayPrice: String {
        priceLabel ?? id.fallbackPriceLabel
    }
}
