import XCTest
@testable import LaTaverneCore

final class CardDeckTests: XCTestCase {
    func testCreateDeckHasFiftyTwoCards() {
        let deck = Deck.createDeck()
        XCTAssertEqual(deck.count, 52)
        XCTAssertEqual(Set(deck.map(\.id)).count, 52, "all card ids must be unique")
    }

    func testAcesCarryMajorPenalty() {
        let deck = Deck.createDeck()
        let aces = deck.filter { $0.rank == .ace }
        XCTAssertEqual(aces.count, 4)
        XCTAssertTrue(aces.allSatisfy { $0.unit == .majorPenalty })
    }

    func testNonAcesCarryStandardPenalty() {
        let deck = Deck.createDeck()
        let nonAces = deck.filter { $0.rank != .ace }
        XCTAssertEqual(nonAces.count, 48)
        XCTAssertTrue(nonAces.allSatisfy { $0.unit == .standardPenalty })
    }

    func testRankNumericValues() {
        XCTAssertEqual(Rank.ace.numericValue, 1)
        XCTAssertEqual(Rank.ten.numericValue, 10)
        XCTAssertEqual(Rank.jack.numericValue, 11)
        XCTAssertEqual(Rank.queen.numericValue, 12)
        XCTAssertEqual(Rank.king.numericValue, 13)
    }

    func testShuffleIsAPermutation() {
        let deck = Deck.createDeck()
        var rng = SeededGenerator(seed: 42)
        let shuffled = Deck.shuffled(deck, using: &rng)
        XCTAssertEqual(Set(shuffled.map(\.id)), Set(deck.map(\.id)))
        XCTAssertEqual(shuffled.count, deck.count)
    }
}

/// Deterministic RNG for reproducible shuffle tests.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
