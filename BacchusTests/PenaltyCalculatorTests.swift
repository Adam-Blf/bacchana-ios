import XCTest
@testable import BacchusCore

final class PenaltyCalculatorTests: XCTestCase {
    func testMultipliersMatchReference() {
        XCTAssertEqual(ContestLevel.none.multiplier, 1)
        XCTAssertEqual(ContestLevel.tie.multiplier, 1)
        XCTAssertEqual(ContestLevel.double.multiplier, 2)
        XCTAssertEqual(ContestLevel.quadruple.multiplier, 4)
    }

    func testStandardPenaltySingular() {
        let result = PenaltyCalculator.calculate(baseAmount: 1, level: .none, unit: .standardPenalty)
        XCTAssertEqual(result.amount, 1)
        XCTAssertEqual(result.displayText, "1 pénalité")
    }

    func testStandardPenaltyPlural() {
        let result = PenaltyCalculator.calculate(baseAmount: 3, level: .double, unit: .standardPenalty)
        XCTAssertEqual(result.amount, 6)
        XCTAssertEqual(result.displayText, "6 pénalités")
    }

    func testMajorPenaltyBase() {
        let result = PenaltyCalculator.calculate(baseAmount: 1, level: .none, unit: .majorPenalty)
        XCTAssertEqual(result.amount, 1)
        XCTAssertEqual(result.displayText, "PÉNALITÉ MAJEURE")
    }

    func testMajorPenaltyEscalated() {
        let result = PenaltyCalculator.calculate(baseAmount: 1, level: .quadruple, unit: .majorPenalty)
        XCTAssertEqual(result.amount, 4)
        XCTAssertEqual(result.displayText, "PÉNALITÉ MAJEURE x4")
    }

    func testCalculateForAceCardIsMajor() {
        let ace = Card(suit: .spades, rank: .ace)
        let result = PenaltyCalculator.calculate(for: ace, level: .none)
        XCTAssertEqual(result.unit, .majorPenalty)
        XCTAssertEqual(result.displayText, "PÉNALITÉ MAJEURE")
    }
}
