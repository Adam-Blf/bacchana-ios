import Foundation

/// The one purchasable plan: a single payment, kept for good.
///
/// WHY THIS ENUM HOLDS EXACTLY ONE CASE, and why that is the point.
///
/// It used to carry three: `premium_monthly` at 4,99, `premium_yearly` at 19,99 and
/// `premium_lifetime` at 34,99. The pricing was settled on 2026-08-30 - one lifetime purchase
/// at 12,99, no subscription, no free trial - and the web app moved. This port did not, which
/// left the App Store paywall offering two subscriptions that will exist in no store and a
/// lifetime price wrong by 22 euros. Nothing could catch it: plans and prices are plain
/// strings, and a paywall that renders is a paywall that looks fine.
///
/// No-subscription is the product argument, not a temporary state, so a one-case enum is the
/// honest shape. It stays an enum rather than a constant because the raw value is matched
/// against store product identifiers in `RevenueCatEntitlements`, and because an optional pack
/// would slot straight in.
///
/// Mirrors the web catalogue in `bacchana/src/components/premium/PremiumPaywallModal.tsx` -
/// note the repo name: the previous reference pointed at `bacchana-site`, which is the
/// showcase and carries no billing. Kept in `BacchanaCore` so the pricing logic stays pure and
/// unit-testable without pulling in any billing SDK.
public enum PremiumPlan: String, Sendable, CaseIterable {
    case lifetime = "premium_lifetime"

    /// Advertised price shown before a real store price is available (guest mode, offline, or
    /// offerings not yet loaded). The price a buyer actually pays always comes from the store.
    public var fallbackPriceLabel: String {
        switch self {
        case .lifetime: return "12,99 €"
        }
    }

    public var title: String {
        switch self {
        case .lifetime: return "À vie"
        }
    }

    public var note: String {
        switch self {
        case .lifetime: return "Paiement unique, à toi pour toujours"
        }
    }
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
