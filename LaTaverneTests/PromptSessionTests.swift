import XCTest
@testable import LaTaverneCore

final class PromptSessionTests: XCTestCase {
    private func makePack(itemCount: Int = 5) -> ContentPack {
        let items = (1...itemCount).map { index in
            PromptItem(
                id: "item-\(index)",
                text: "Prompt \(index) pour {player}",
                textAlt: nil,
                penalty: nil,
                rule: nil,
                targets: nil,
                tags: nil,
                minPlayers: nil
            )
        }
        let meta = PackMeta(id: "test-pack", mode: .picolo, lang: "fr", title: "Test", subtitle: nil, premium: false, minPlayers: nil, intensity: .soft)
        return ContentPack(schemaVersion: 1, pack: meta, items: items)
    }

    func testDrawNextNeverRepeatsBeforeExhaustion() {
        let session = PromptSession(pack: makePack(itemCount: 5))
        var drawnIDs: [String] = []
        for _ in 0..<5 {
            guard let item = session.drawNext(playerCount: 4) else { return XCTFail("expected an item") }
            drawnIDs.append(item.id)
        }
        XCTAssertEqual(Set(drawnIDs).count, 5, "no repeats within a full cycle")
    }

    func testDrawNextReshufflesAfterExhaustion() {
        let session = PromptSession(pack: makePack(itemCount: 3))
        for _ in 0..<3 { _ = session.drawNext(playerCount: 4) }
        XCTAssertTrue(session.drawPile.isEmpty)
        let next = session.drawNext(playerCount: 4)
        XCTAssertNotNil(next, "pile reshuffles from discard once exhausted")
    }

    func testInterpolatesPlayerPlaceholders() {
        let result = PromptSession.interpolate("{player} regarde {player2} droit dans les yeux.", player: "Alice", player2: "Bob")
        XCTAssertEqual(result, "Alice regarde Bob droit dans les yeux.")
    }

    func testPersistentRuleTicksDownAndExpires() {
        var items = makePack(itemCount: 1).items
        items[0] = PromptItem(
            id: items[0].id,
            text: items[0].text,
            textAlt: nil,
            penalty: nil,
            rule: PromptRule(type: .persistent, durationTurns: 2),
            targets: nil,
            tags: nil,
            minPlayers: nil
        )
        let meta = PackMeta(id: "test-pack", mode: .picolo, lang: "fr", title: "Test", subtitle: nil, premium: false, minPlayers: nil, intensity: .soft)
        let pack = ContentPack(schemaVersion: 1, pack: meta, items: items)
        let session = PromptSession(pack: pack)

        _ = session.drawNext(playerCount: 4)
        XCTAssertEqual(session.activeRules.count, 1)
        XCTAssertEqual(session.activeRules.first?.remainingTurns, 2)

        session.tickTurn()
        XCTAssertEqual(session.activeRules.first?.remainingTurns, 1)

        session.tickTurn()
        XCTAssertTrue(session.activeRules.isEmpty, "rule expires once remainingTurns reaches zero")
    }

    func testMinPlayersFiltersEligibleItems() {
        var items = makePack(itemCount: 2).items
        items[0] = PromptItem(id: items[0].id, text: items[0].text, textAlt: nil, penalty: nil, rule: nil, targets: nil, tags: nil, minPlayers: 6)
        let meta = PackMeta(id: "test-pack", mode: .picolo, lang: "fr", title: "Test", subtitle: nil, premium: false, minPlayers: nil, intensity: .soft)
        let pack = ContentPack(schemaVersion: 1, pack: meta, items: items)
        let session = PromptSession(pack: pack)

        let drawn = session.drawNext(playerCount: 3)
        XCTAssertEqual(drawn?.id, items[1].id, "item requiring 6 players is skipped with only 3 present")
    }
}
