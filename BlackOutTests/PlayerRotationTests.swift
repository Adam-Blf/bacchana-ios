import XCTest
@testable import BlackOutCore

final class PlayerRotationTests: XCTestCase {
    func testNextIndexWrapsAround() {
        let players = [Player(name: "Alice"), Player(name: "Bob"), Player(name: "Chloé")]
        XCTAssertEqual(PlayerRotation.nextIndex(from: 0, players: players), 1)
        XCTAssertEqual(PlayerRotation.nextIndex(from: 2, players: players), 0)
    }

    func testNextIndexSkipsInactivePlayers() {
        let players = [Player(name: "Alice"), Player(name: "Bob"), Player(name: "Chloé")]
        players[1].active = false
        XCTAssertEqual(PlayerRotation.nextIndex(from: 0, players: players), 2)
    }

    func testNextIndexReturnsSameIndexWhenAllInactive() {
        let players = [Player(name: "Alice"), Player(name: "Bob")]
        players.forEach { $0.active = false }
        XCTAssertEqual(PlayerRotation.nextIndex(from: 0, players: players), 0)
    }
}

final class BorderlandEngineTests: XCTestCase {
    func testDrawCardMovesCardToDiscardPile() {
        let players = [Player(name: "Alice"), Player(name: "Bob")]
        let engine = BorderlandEngine(players: players, shuffledDeck: Deck.createDeck())
        let drawCount = engine.drawPile.count
        let card = engine.drawCard()
        XCTAssertNotNil(card)
        XCTAssertEqual(engine.drawPile.count, drawCount - 1)
        XCTAssertEqual(engine.discardPile.last?.id, card?.id)
    }

    func testResolvePenaltyAppliesToLoserAndAdvancesTurn() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let engine = BorderlandEngine(players: [alice, bob], shuffledDeck: Deck.createDeck())
        let startIndex = engine.currentPlayerIndex
        let card = Card(suit: .hearts, rank: .five)
        engine.resolvePenalty(for: card, loser: bob)
        XCTAssertEqual(bob.penaltiesStandard, 5)
        XCTAssertNotEqual(engine.currentPlayerIndex, startIndex)
    }

    func testContestEscalationCapsAtQuadruple() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let engine = BorderlandEngine(players: [alice, bob], shuffledDeck: Deck.createDeck())
        engine.startContest(against: bob)
        for _ in 0..<10 { engine.escalateContest() }
        XCTAssertEqual(engine.activeContest?.level, .quadruple)
    }
}
