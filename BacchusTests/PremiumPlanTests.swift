import XCTest
@testable import BacchusCore

final class PremiumPlanTests: XCTestCase {
    func testFallbackPricesMatchCatalog() {
        XCTAssertEqual(PremiumPlan.monthly.fallbackPriceLabel, "4,99 €")
        XCTAssertEqual(PremiumPlan.yearly.fallbackPriceLabel, "19,99 €")
        XCTAssertEqual(PremiumPlan.lifetime.fallbackPriceLabel, "34,99 €")
    }

    func testOnlyLifetimeIsHighlighted() {
        XCTAssertFalse(PremiumPlan.monthly.isHighlighted)
        XCTAssertFalse(PremiumPlan.yearly.isHighlighted)
        XCTAssertTrue(PremiumPlan.lifetime.isHighlighted)
    }

    func testCatalogOrderShowsLifetimeLast() {
        XCTAssertEqual(PremiumPlan.catalogOrder, [.monthly, .yearly, .lifetime])
    }

    func testDisplayPriceFallsBackWithoutRealPrice() {
        let package = PremiumPackage(id: .yearly, priceLabel: nil)
        XCTAssertEqual(package.displayPrice, "19,99 €")
    }

    func testDisplayPricePrefersRealStorePrice() {
        let package = PremiumPackage(id: .yearly, priceLabel: "19,99 € / an")
        XCTAssertEqual(package.displayPrice, "19,99 € / an")
    }

    func testAllCasesCoverThreeCatalogPlans() {
        XCTAssertEqual(PremiumPlan.allCases.count, 3)
        XCTAssertEqual(Set(PremiumPlan.allCases), Set(PremiumPlan.catalogOrder))
    }
}
