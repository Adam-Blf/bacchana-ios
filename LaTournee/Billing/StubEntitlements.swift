import Foundation
import LaTourneeCore

/// Default entitlement provider until a RevenueCat API key is configured. Every premium pack
/// stays locked, which is the safe default for App Review and for anyone who clones the repo
/// without the local billing secrets (`Config.local.xcconfig`, gitignored).
final class StubEntitlements: EntitlementProviding {
    private(set) var isPremium = false

    func refresh() async {}

    func restorePurchases() async throws {
        // No-op in guest mode: nothing was ever purchased without a real billing provider.
    }

    func fetchPackages() async -> [PremiumPackage] {
        []
    }

    func purchase(_ package: PremiumPackage) async throws {
        throw EntitlementError.billingUnavailable
    }
}
