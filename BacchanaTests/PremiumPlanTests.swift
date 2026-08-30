import XCTest
@testable import BacchanaCore

final class PremiumPlanTests: XCTestCase {
    /// The catalogue is the price list a buyer reads, so it is pinned here rather than left to
    /// a screenshot. This test exists because the port kept selling `premium_monthly` at 4,99,
    /// `premium_yearly` at 19,99 and a lifetime at 34,99 for weeks after the price was settled
    /// at a single 12,99 - plain strings that render perfectly while being wrong.
    func testCatalogIsOneLifetimePlanAt1299() {
        XCTAssertEqual(PremiumPlan.allCases, [.lifetime])
        XCTAssertEqual(PremiumPlan.lifetime.rawValue, "premium_lifetime")
        XCTAssertEqual(PremiumPlan.lifetime.fallbackPriceLabel, "12,99 €")
    }

    /// Named explicitly: these are the two identifiers that must never come back, because a
    /// subscription contradicts the one thing the product promises.
    func testNoSubscriptionProductIdentifierSurvives() {
        for plan in PremiumPlan.allCases {
            XCTAssertFalse(plan.rawValue.contains("monthly"))
            XCTAssertFalse(plan.rawValue.contains("yearly"))
        }
    }

    func testNoteStatesTheSinglePayment() {
        XCTAssertEqual(PremiumPlan.lifetime.note, "Paiement unique, à toi pour toujours")
    }

    func testDisplayPriceFallsBackWithoutRealPrice() {
        let package = PremiumPackage(id: .lifetime, priceLabel: nil)
        XCTAssertEqual(package.displayPrice, "12,99 €")
    }

    func testDisplayPricePrefersRealStorePrice() {
        // The store is the authority on price - a local label must never win over it, or the
        // screen shows one number while the sheet charges another.
        let package = PremiumPackage(id: .lifetime, priceLabel: "12,99 €")
        XCTAssertEqual(package.displayPrice, "12,99 €")
    }

    func testRawValueMatchesStoreProductIdentifier() {
        // RevenueCatEntitlements builds a plan straight from the store product identifier.
        XCTAssertEqual(PremiumPlan(rawValue: "premium_lifetime"), .lifetime)
        XCTAssertNil(PremiumPlan(rawValue: "premium_monthly"))
        XCTAssertNil(PremiumPlan(rawValue: "unrelated_product"))
    }
}
