import Foundation

/// Chooses the entitlement provider at launch: `RevenueCatEntitlements` when a RevenueCat API
/// key is configured (`LaTaverne/Config/Config.xcconfig` + local, gitignored,
/// `Config.local.xcconfig`, see README > Monetisation), `StubEntitlements` (guest mode) when
/// absent. CI, and anyone cloning the repo without the local xcconfig, build and run in guest
/// mode - never crash on missing configuration.
enum EntitlementsFactory {
    private static let infoPlistKey = "REVENUECAT_API_KEY"

    static func make() -> EntitlementProviding {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String,
              !apiKey.isEmpty else {
            return StubEntitlements()
        }
        return RevenueCatEntitlements(apiKey: apiKey)
    }
}
