import Foundation

/// Abstraction over premium entitlement state, so the rest of the app never
/// talks to RevenueCat or StoreKit directly.
protocol EntitlementProviding: AnyObject {
    var isPremium: Bool { get }
    func refresh() async
    func restorePurchases() async throws
}

// TODO(billing): wire RevenueCat (preferred, cross-platform parity with the
// Android app) or plain StoreKit 2 once the App Store Connect in-app
// purchase (non-consumable "La Taverne Premium") is created. Until then every
// build ships with `StubEntitlements`, isPremium always false, premium packs
// stay visibly locked in the Hub. See README > Conformite App Store.
//
// StoreKit 2 sketch (kept commented, not compiled, for the future PR):
//
// final class StoreKitEntitlements: EntitlementProviding {
//     private(set) var isPremium = false
//     private let premiumProductID = "com.beloucif.lataverne.premium"
//
//     func refresh() async {
//         for await result in Transaction.currentEntitlements {
//             guard case .verified(let transaction) = result else { continue }
//             if transaction.productID == premiumProductID {
//                 isPremium = true
//             }
//         }
//     }
//
//     func restorePurchases() async throws {
//         try await AppStore.sync()
//         await refresh()
//     }
// }
