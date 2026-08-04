import Foundation
import MeskovaCore

/// Abstraction over premium entitlement state, so the rest of the app never talks to
/// RevenueCat or StoreKit directly. `RevenueCatEntitlements` implements this when a RevenueCat
/// API key is configured (see `EntitlementsFactory`, `Config.xcconfig`); `StubEntitlements`
/// (guest mode, every premium pack stays locked) otherwise. See README > Monetisation.
protocol EntitlementProviding: AnyObject {
    var isPremium: Bool { get }
    func refresh() async
    func restorePurchases() async throws

    /// Best-effort catalog fetch for the paywall (real store prices). Returns `[]` in guest
    /// mode, offline, or on any billing failure - callers must fall back to
    /// `PremiumPlan.fallbackPriceLabel` and disable the purchase button, never crash.
    func fetchPackages() async -> [PremiumPackage]

    /// Initiates a real purchase. Throws `EntitlementError.billingUnavailable` in guest mode.
    func purchase(_ package: PremiumPackage) async throws
}

/// Errors surfaced by `EntitlementProviding` conformers. Never a crash, always a message the
/// paywall can show ("Bientôt disponible" / réessaie plus tard).
enum EntitlementError: Error {
    /// Thrown by `StubEntitlements` when a purchase is attempted without a configured billing
    /// provider (guest mode).
    case billingUnavailable
    /// Thrown by `RevenueCatEntitlements` when the requested plan has no matching store package
    /// (offerings not loaded yet, or dashboard misconfiguration).
    case packageUnavailable
}
