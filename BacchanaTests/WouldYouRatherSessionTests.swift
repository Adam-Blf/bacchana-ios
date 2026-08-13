import XCTest
@testable import BacchanaCore

final class WouldYouRatherSessionTests: XCTestCase {
    private let alice = Player(name: "Alice")
    private let bob = Player(name: "Bob")
    private let carol = Player(name: "Carol")

    private func makeQuestions(_ count: Int) -> [WouldYouRatherQuestion] {
        (1...count).map {
            WouldYouRatherQuestion(id: "q\($0)", optionA: "A\($0)", optionB: "B\($0)")
        }
    }

    func testCreateSessionSetsUpFirstQuestionAndActivePlayersOnly() {
        bob.active = false
        let session = createWouldYouRatherSession(questions: makeQuestions(3), players: [alice, bob, carol], rng: { 0 })

        XCTAssertNotNil(session.currentQuestion)
        XCTAssertEqual(session.queue.count, 2)
        XCTAssertEqual(session.phase, .voting)
        XCTAssertEqual(session.roundNumber, 1)
        XCTAssertEqual(session.players.map(\.id).sorted(), [alice.id, carol.id].sorted())
        bob.active = true
    }

    func testCastVoteRecordsChoiceForKnownPlayerDuringVoting() {
        let session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })

        let next = castVote(session, playerId: alice.id, side: .optionA)

        XCTAssertEqual(next.votes[alice.id], .optionA)
    }

    func testCastVoteIsIgnoredForUnknownPlayer() {
        let session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })

        let next = castVote(session, playerId: "ghost", side: .optionA)

        XCTAssertTrue(next.votes.isEmpty)
    }

    func testCastVoteOverwritesPreviousChoiceForSamePlayer() {
        var session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })
        session = castVote(session, playerId: alice.id, side: .optionA)

        session = castVote(session, playerId: alice.id, side: .optionB)

        XCTAssertEqual(session.votes[alice.id], .optionB)
        XCTAssertEqual(session.votes.count, 1)
    }

    func testAllVotedIsTrueOnlyWhenEveryActivePlayerHasVoted() {
        var session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })
        XCTAssertFalse(allVoted(session))

        session = castVote(session, playerId: alice.id, side: .optionA)
        XCTAssertFalse(allVoted(session))

        session = castVote(session, playerId: bob.id, side: .optionB)
        XCTAssertTrue(allVoted(session))
    }

    func testRevealVotesPenalizesTheMinority() {
        var session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob, carol], rng: { 0 })
        session = castVote(session, playerId: alice.id, side: .optionA)
        session = castVote(session, playerId: bob.id, side: .optionA)
        session = castVote(session, playerId: carol.id, side: .optionB)

        let next = revealVotes(session)

        XCTAssertEqual(next.phase, .reveal)
        XCTAssertEqual(next.penaltyCounts[carol.id], minorityPenalty)
        XCTAssertNil(next.penaltyCounts[alice.id])
        XCTAssertNil(next.penaltyCounts[bob.id])
    }

    func testRevealVotesOnPerfectTieNobodyIsPenalized() {
        var session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })
        session = castVote(session, playerId: alice.id, side: .optionA)
        session = castVote(session, playerId: bob.id, side: .optionB)

        let next = revealVotes(session)

        XCTAssertEqual(next.phase, .reveal)
        XCTAssertTrue(next.penaltyCounts.isEmpty)
    }

    func testRevealVotesOnUnanimousVoteNobodyIsPenalized() {
        var session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob, carol], rng: { 0 })
        session = castVote(session, playerId: alice.id, side: .optionA)
        session = castVote(session, playerId: bob.id, side: .optionA)
        session = castVote(session, playerId: carol.id, side: .optionA)

        let next = revealVotes(session)

        XCTAssertEqual(next.phase, .reveal)
        XCTAssertTrue(next.penaltyCounts.isEmpty)
    }

    func testPenaltiesAccumulateAcrossMultipleRounds() {
        // Carol lands in the minority on two separate rounds: her penalty
        // count must sum across `nextRound`, not just record the latest one.
        var session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob, carol], rng: { 0 })
        session = castVote(session, playerId: alice.id, side: .optionA)
        session = castVote(session, playerId: bob.id, side: .optionA)
        session = castVote(session, playerId: carol.id, side: .optionB)
        session = revealVotes(session)
        XCTAssertEqual(session.penaltyCounts[carol.id], minorityPenalty)

        session = nextRound(session)
        XCTAssertEqual(session.phase, .voting)
        XCTAssertTrue(session.votes.isEmpty, "votes must reset between rounds")

        session = castVote(session, playerId: alice.id, side: .optionB)
        session = castVote(session, playerId: bob.id, side: .optionB)
        session = castVote(session, playerId: carol.id, side: .optionA)
        session = revealVotes(session)

        XCTAssertEqual(session.penaltyCounts[carol.id], minorityPenalty * 2, "penalty must accumulate, not reset, across rounds")
        XCTAssertNil(session.penaltyCounts[alice.id])
        XCTAssertNil(session.penaltyCounts[bob.id])
    }

    func testQueueExhaustionFinishesSession() {
        var session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })
        XCTAssertEqual(session.queue.count, 1)

        session = castVote(session, playerId: alice.id, side: .optionA)
        session = castVote(session, playerId: bob.id, side: .optionB)
        session = revealVotes(session)
        session = nextRound(session)
        XCTAssertEqual(session.phase, .voting)
        XCTAssertNotNil(session.currentQuestion)

        session = castVote(session, playerId: alice.id, side: .optionA)
        session = castVote(session, playerId: bob.id, side: .optionB)
        session = revealVotes(session)
        session = nextRound(session)

        XCTAssertEqual(session.phase, .finished)
        XCTAssertNil(session.currentQuestion)
        XCTAssertTrue(session.queue.isEmpty)
    }

    func testRevealVotesIsIgnoredOutsideVotingPhase() {
        var session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })
        session = castVote(session, playerId: alice.id, side: .optionA)
        session = castVote(session, playerId: bob.id, side: .optionB)
        session = revealVotes(session)

        let unchanged = revealVotes(session)

        XCTAssertEqual(unchanged.penaltyCounts, session.penaltyCounts)
        XCTAssertEqual(unchanged.phase, .reveal)
    }

    func testNextRoundIsIgnoredOutsideRevealPhase() {
        let session = createWouldYouRatherSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })

        let unchanged = nextRound(session)

        XCTAssertEqual(unchanged.roundNumber, session.roundNumber)
        XCTAssertEqual(unchanged.phase, .voting)
    }
}
