import XCTest
@testable import BacchusCore

final class ContentPackDecodingTests: XCTestCase {
    func testDecodesMinimalPack() throws {
        let json = """
        {
          "schemaVersion": 1,
          "pack": {
            "id": "picolo-soiree",
            "mode": "picolo",
            "lang": "fr",
            "title": "Picolo - Soirée",
            "premium": false
          },
          "items": [
            { "id": "p-001", "text": "Bois un coup." }
          ]
        }
        """.data(using: .utf8)!

        let pack = try JSONDecoder().decode(ContentPack.self, from: json)
        XCTAssertEqual(pack.pack.id, "picolo-soiree")
        XCTAssertEqual(pack.pack.mode, .picolo)
        XCTAssertFalse(pack.pack.premium)
        XCTAssertEqual(pack.items.count, 1)
        XCTAssertEqual(pack.items[0].text, "Bois un coup.")
    }

    func testDecodesFullItemWithRuleAndPenalty() throws {
        let json = """
        {
          "schemaVersion": 1,
          "pack": { "id": "borderland-core", "mode": "borderland", "lang": "fr", "title": "Borderland", "premium": false, "minPlayers": 3, "intensity": "hot" },
          "items": [
            {
              "id": "b-001",
              "text": "{player} désigne {player2} comme cible.",
              "penalty": { "sips": 2 },
              "rule": { "type": "persistent", "durationTurns": 3 },
              "targets": "pair",
              "tags": ["duel"],
              "minPlayers": 2
            }
          ]
        }
        """.data(using: .utf8)!

        let pack = try JSONDecoder().decode(ContentPack.self, from: json)
        let item = try XCTUnwrap(pack.items.first)
        XCTAssertEqual(item.penalty?.sips, 2)
        XCTAssertEqual(item.rule?.type, .persistent)
        XCTAssertEqual(item.rule?.durationTurns, 3)
        XCTAssertEqual(item.targets, .pair)
        XCTAssertEqual(pack.pack.intensity, .hot)
    }
}
