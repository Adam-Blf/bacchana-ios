import Foundation

/// Default entitlement provider until real billing ships. Every premium
/// pack stays locked, which is the safe default for App Review.
final class StubEntitlements: EntitlementProviding {
    private(set) var isPremium = false

    func refresh() async {}

    func restorePurchases() async throws {
        // No-op until StoreKit 2 / RevenueCat is wired in.
    }
}
