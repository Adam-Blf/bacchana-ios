import XCTest
@testable import BacchanaCore

final class RankingSessionTests: XCTestCase {
    private let alice = Player(name: "Alice")
    private let bob = Player(name: "Bob")
    private let carol = Player(name: "Carol")
    private let dave = Player(name: "Dave")

    private func makeQuestions(_ count: Int) -> [RankingQuestion] {
        (1...count).map { RankingQuestion(id: "q\($0)", text: "Question \($0)") }
    }

    private var allPlayers: [Player] { [alice, bob, carol, dave] }

    func testCreateRankingSessionSetsUpFirstRoundWithFourDistinctChoices() {
        let session = createRankingSession(questions: makeQuestions(10), players: allPlayers, rng: { 0 })

        XCTAssertEqual(session.phase, .handoff)
        XCTAssertEqual(session.judgeIndex, 0)
        XCTAssertEqual(session.roundNumber, 1)
        XCTAssertEqual(session.queue.count, 9)
        let round = try? XCTUnwrap(session.round)
        XCTAssertEqual(round?.choices.count, 4)
        XCTAssertEqual(Set(round?.choices.map(\.id) ?? []).count, 4, "choices must be distinct")
        XCTAssertTrue(round?.choices.contains(where: { $0.id == round?.question.id }) ?? false)
    }

    func testGetContestantsExcludesTheJudge() {
        let session = createRankingSession(questions: makeQuestions(5), players: allPlayers, rng: { 0 })

        let contestants = getContestants(session)

        XCTAssertEqual(contestants.count, 3)
        XCTAssertFalse(contestants.contains { $0.id == getJudge(session)?.id })
    }

    func testToggleRankedIgnoresTheJudgeAndOutsideJudgingPhase() {
        var session = createRankingSession(questions: makeQuestions(5), players: allPlayers, rng: { 0 })
        let judgeId = getJudge(session)!.id

        let unchangedOutsidePhase = toggleRanked(session, playerId: bob.id)
        XCTAssertEqual(unchangedOutsidePhase.ranked, [])

        session = startJudging(session)
        let judgeAttempt = toggleRanked(session, playerId: judgeId)
        XCTAssertEqual(judgeAttempt.ranked, [])
    }

    func testToggleRankedTracksTapOrderAndAllowsUntoggle() {
        var session = startJudging(createRankingSession(questions: makeQuestions(5), players: allPlayers, rng: { 0 }))

        session = toggleRanked(session, playerId: bob.id)
        session = toggleRanked(session, playerId: carol.id)
        XCTAssertEqual(session.ranked, [bob.id, carol.id])

        session = toggleRanked(session, playerId: bob.id)
        XCTAssertEqual(session.ranked, [carol.id])
    }

    func testConfirmRankingRequiresEveryContestantRanked() {
        var session = startJudging(createRankingSession(questions: makeQuestions(5), players: allPlayers, rng: { 0 }))
        session = toggleRanked(session, playerId: bob.id)

        let incomplete = confirmRanking(session)
        XCTAssertEqual(incomplete.phase, .judging, "confirming with a partial ranking must be a no-op")

        session = toggleRanked(session, playerId: carol.id)
        session = toggleRanked(session, playerId: dave.id)
        let complete = confirmRanking(session)
        XCTAssertEqual(complete.phase, .return)
    }

    func testGuessCorrectPenalizesOnlyTheJudge() {
        var session = createRankingSession(questions: makeQuestions(5), players: allPlayers, rng: { 0 })
        let judgeId = getJudge(session)!.id
        session = startJudging(session)
        session = toggleRanked(session, playerId: bob.id)
        session = toggleRanked(session, playerId: carol.id)
        session = toggleRanked(session, playerId: dave.id)
        session = confirmRanking(session)
        session = startGuessing(session)
        let realQuestionId = session.round!.question.id

        let next = guessQuestion(session, questionId: realQuestionId)

        XCTAssertEqual(next.phase, .reveal)
        XCTAssertEqual(next.penaltyCounts[judgeId], rankingJudgePenalty)
        XCTAssertEqual(next.penaltyCounts.count, 1, "only the judge takes a penalty on a correct guess")
    }

    func testGuessWrongPenalizesEveryContestantButNotTheJudge() {
        var session = createRankingSession(questions: makeQuestions(5), players: allPlayers, rng: { 0 })
        let judgeId = getJudge(session)!.id
        session = startJudging(session)
        session = toggleRanked(session, playerId: bob.id)
        session = toggleRanked(session, playerId: carol.id)
        session = toggleRanked(session, playerId: dave.id)
        session = confirmRanking(session)
        session = startGuessing(session)
        let decoyId = session.round!.choices.first { $0.id != session.round!.question.id }!.id

        let next = guessQuestion(session, questionId: decoyId)

        XCTAssertEqual(next.phase, .reveal)
        XCTAssertNil(next.penaltyCounts[judgeId])
        for contestant in [bob, carol, dave] {
            XCTAssertEqual(next.penaltyCounts[contestant.id], rankingGroupPenalty)
        }
    }

    func testNextRoundRotatesJudgeAndResetsRoundState() {
        var session = createRankingSession(questions: makeQuestions(5), players: allPlayers, rng: { 0 })
        session = startJudging(session)
        session = toggleRanked(session, playerId: bob.id)
        session = toggleRanked(session, playerId: carol.id)
        session = toggleRanked(session, playerId: dave.id)
        session = confirmRanking(session)
        session = startGuessing(session)
        session = guessQuestion(session, questionId: session.round!.question.id)

        let next = nextRound(session, rng: { 0 })

        XCTAssertEqual(next.judgeIndex, 1)
        XCTAssertEqual(next.roundNumber, 2)
        XCTAssertEqual(next.ranked, [])
        XCTAssertNil(next.guessedId)
        XCTAssertEqual(next.phase, .handoff)
    }

    func testQueueExhaustionFinishesSession() {
        var session = createRankingSession(questions: makeQuestions(1), players: allPlayers, rng: { 0 })
        XCTAssertTrue(session.queue.isEmpty)

        session = startJudging(session)
        session = toggleRanked(session, playerId: bob.id)
        session = toggleRanked(session, playerId: carol.id)
        session = toggleRanked(session, playerId: dave.id)
        session = confirmRanking(session)
        session = startGuessing(session)
        session = guessQuestion(session, questionId: session.round!.question.id)
        session = nextRound(session, rng: { 0 })

        XCTAssertEqual(session.phase, .finished)
        XCTAssertNil(session.round)
    }

    func testGetJudgeReturnsNilWhenRosterIsEmpty() {
        let session = createRankingSession(questions: makeQuestions(1), players: [], rng: { 0 })

        XCTAssertNil(getJudge(session))
    }
}
