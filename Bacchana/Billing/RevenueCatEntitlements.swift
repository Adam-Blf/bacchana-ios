import Foundation
import RevenueCat
import BacchanaCore

/// Entitlement identifier configured in the RevenueCat dashboard. Mirrors the web
/// `PREMIUM_ENTITLEMENT_ID` (`bacchana-site/src/lib/billing.ts`) and the Android
/// `PREMIUM_ENTITLEMENT_ID` (`com.beloucif.bacchana.core.PremiumPlan`).
///
/// Product rename (v0.16.0, La Tournee -> Bacchana, final name): renamed to "Bacchana Pro"
/// (no accent, exact RevenueCat dashboard id, already created there) - like the v0.15.0 rename,
/// the entitlement id itself moves. Safe because the app is not yet published: there are no
/// existing subscribers to migrate.
private let premiumEntitlementID = "Bacchana Pro"

/// Real billing provider, created by `EntitlementsFactory` only when a RevenueCat API key is
/// configured. Talks to StoreKit through RevenueCat; the rest of the app only ever sees
/// `EntitlementProviding` and `BacchanaCore.PremiumPackage`, never RevenueCat types directly.
final class RevenueCatEntitlements: NSObject, EntitlementProviding {
    // `isPremium` and `cachedPackages` are written from plain `async` call sites (refresh,
    // restore, purchase) and from the RevenueCat delegate callback below, which RevenueCat
    // invokes on an unspecified thread. `EntitlementProviding.isPremium` is a synchronous
    // requirement, so making this an `actor` would force every read through `await` across the
    // whole app. Writes here don't overlap in practice (delegate callbacks and user-triggered
    // purchases are serialized by the single-paywall UI), and `nonisolated(unsafe)` is the
    // documented Swift 6 migration escape hatch for exactly this delegate-bridging shape.
    nonisolated(unsafe) private(set) var isPremium = false
    nonisolated(unsafe) private var cachedPackages: [PremiumPlan: Package] = [:]

    init(apiKey: String) {
        super.init()
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
    }

    func refresh() async {
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        apply(info)
    }

    func restorePurchases() async throws {
        apply(try await Purchases.shared.restorePurchases())
    }

    func fetchPackages() async -> [PremiumPackage] {
        guard let offerings = try? await Purchases.shared.offerings(),
              let current = offerings.current else { return [] }

        var packages: [PremiumPackage] = []
        for package in current.availablePackages {
            guard let plan = PremiumPlan(rawValue: package.storeProduct.productIdentifier) else { continue }
            cachedPackages[plan] = package
            packages.append(PremiumPackage(id: plan, priceLabel: package.localizedPriceString))
        }
        return packages
    }

    func purchase(_ package: PremiumPackage) async throws {
        guard let rcPackage = cachedPackages[package.id] else {
            throw EntitlementError.packageUnavailable
        }
        let result = try await Purchases.shared.purchase(package: rcPackage)
        guard !result.userCancelled else { return }
        apply(result.customerInfo)
    }

    private func apply(_ info: CustomerInfo) {
        isPremium = info.entitlements[premiumEntitlementID]?.isActive == true
    }
}

extension RevenueCatEntitlements: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        apply(customerInfo)
    }
}
