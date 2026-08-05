import XCTest
@testable import LaTourneeCore

final class TribunalSessionTests: XCTestCase {
    func testPickAccusedExcludesAuthor() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let players = [alice, bob]
        // Fixed picker always returns index 0: without exclusion this would
        // pick the author back, which the engine must never do while an
        // alternative exists.
        let session = TribunalSession(players: players, randomIndex: { _ in 0 })

        let accused = session.pickAccused(excluding: alice.id)

        XCTAssertEqual(accused?.id, bob.id)
    }

    func testPickAccusedFallsBackToFullRosterWhenAuthorIsOnlyPlayer() {
        let alice = Player(name: "Alice")
        let session = TribunalSession(players: [alice], randomIndex: { _ in 0 })

        let accused = session.pickAccused(excluding: alice.id)

        XCTAssertEqual(accused?.id, alice.id)
    }

    func testStartTrialFromAppChargesWhenPoolIsEmpty() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let session = TribunalSession(players: [alice, bob], randomIndex: { _ in 0 })

        session.startTrial(from: [])

        XCTAssertNotNil(session.current)
        XCTAssertNil(session.current?.authorID)
        XCTAssertNotNil(session.accused)
        XCTAssertTrue(session.pool.isEmpty)
    }

    func testStartTrialExcludesAccusationAuthorFromAccused() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let session = TribunalSession(players: [alice, bob], randomIndex: { _ in 0 })
        let accusation = TribunalAccusation(text: "Ne dit jamais bonjour.", authorID: alice.id)

        session.startTrial(from: [accusation])

        XCTAssertEqual(session.current?.id, accusation.id)
        XCTAssertEqual(session.accused?.id, bob.id)
    }

    func testResolveVerdictMajorityGuiltyIncrementsPenaltyOnce() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let session = TribunalSession(players: [alice, bob], randomIndex: { _ in 0 })
        session.startTrial(from: [])
        let accusedID = try! XCTUnwrap(session.accused?.id)

        let verdict = session.resolveVerdict(votesGuilty: 2, votesInnocent: 1)

        XCTAssertEqual(verdict, .guilty)
        XCTAssertEqual(session.penaltyCounts[accusedID], 1)
        XCTAssertEqual(session.trialsPlayed, 1)
    }

    func testResolveVerdictTieResolvesInnocentAndDoesNotPenalize() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let session = TribunalSession(players: [alice, bob], randomIndex: { _ in 0 })
        session.startTrial(from: [])

        let verdict = session.resolveVerdict(votesGuilty: 1, votesInnocent: 1)

        XCTAssertEqual(verdict, .innocent)
        XCTAssertTrue(session.penaltyCounts.isEmpty)
    }

    func testResolveVerdictNeverMutatesPlayerPenaltyFields() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let session = TribunalSession(players: [alice, bob], randomIndex: { _ in 0 })
        session.startTrial(from: [])

        session.resolveVerdict(votesGuilty: 2, votesInnocent: 0)

        XCTAssertEqual(alice.penaltiesStandard, 0)
        XCTAssertEqual(alice.penaltiesMajor, 0)
        XCTAssertEqual(bob.penaltiesStandard, 0)
        XCTAssertEqual(bob.penaltiesMajor, 0)
    }

    func testChargeTextInterpolatesAccusedName() {
        let alice = Player(name: "Alice")
        let bob = Player(name: "Bob")
        let session = TribunalSession(players: [alice, bob], randomIndex: { _ in 0 })
        let accusation = TribunalAccusation(text: "{player} a triché.", authorID: alice.id)

        session.startTrial(from: [accusation])

        XCTAssertEqual(session.chargeText, "Bob a triché.")
    }
}
