import XCTest
@testable import BacchanaCore

/// Fixed-value RNG stub: advances through `values` on each call, then holds
/// on the last value so callers past the end still get a valid draw.
private func makeSequenceRng(_ values: [Double]) -> QuizRng {
    var index = 0
    return {
        let value = values[index]
        index = min(index + 1, values.count - 1)
        return value
    }
}

final class QuizSessionTests: XCTestCase {
    private let alice = Player(name: "Alice")
    private let bob = Player(name: "Bob")

    private func makeQuestions(_ count: Int) -> [QuizQuestion] {
        (1...count).map {
            QuizQuestion(id: "q\($0)", category: .cultureGenerale, question: "Q\($0)", answer: "A\($0)")
        }
    }

    func testCreateQuizSessionSetsUpFirstQuestionAndRollsPoints() {
        let session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: { 0 })

        XCTAssertNotNil(session.currentQuestion)
        XCTAssertEqual(session.queue.count, 2)
        XCTAssertEqual(session.currentPoints, 1)
        XCTAssertEqual(session.phase, .question)
        XCTAssertEqual(session.turnNumber, 1)
        XCTAssertEqual(session.currentPlayerIndex, 0)
    }

    func testAnswerCorrectMovesPointsToPotAndSwitchesToChoicePhase() {
        let session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: { 0 })

        let next = answerCorrect(session)

        XCTAssertEqual(next.pots[alice.id], session.currentPoints)
        XCTAssertEqual(next.phase, .choice)
        XCTAssertNil(next.lastOutcome)
    }

    func testAnswerCorrectIsIgnoredOutsideQuestionPhase() {
        let session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: { 0 })
        let choiceState = answerCorrect(session)

        let unchanged = answerCorrect(choiceState)

        XCTAssertEqual(unchanged.pots, choiceState.pots)
        XCTAssertEqual(unchanged.phase, .choice)
    }

    func testAnswerWrongTakesPotPlusPointsAsPenaltyAndAdvances() {
        let session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: { 0 })
        let currentPoints = session.currentPoints

        let next = answerWrong(session, rng: { 0 })

        XCTAssertEqual(next.penaltyCounts[alice.id], currentPoints)
        XCTAssertEqual(next.pots[alice.id], 0)
        XCTAssertEqual(next.lastOutcome, QuizOutcome(kind: .busted, playerId: alice.id, amount: currentPoints))
        XCTAssertEqual(next.currentPlayerIndex, 1)
        XCTAssertEqual(next.turnNumber, 2)
        XCTAssertEqual(next.phase, .question)
    }

    func testAnswerWrongAccumulatesExistingPotIntoPenalty() {
        // A pot carried over from a previous "keep" round must be added to
        // the new question's points when the player busts.
        var session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: { 0 })
        session.pots[alice.id] = 4
        XCTAssertEqual(session.currentPoints, 1)

        let next = answerWrong(session, rng: { 0 })

        XCTAssertEqual(next.penaltyCounts[alice.id], 5)
        XCTAssertEqual(next.pots[alice.id], 0)
    }

    func testDistributePotRecordsGloryWithoutPenaltyAndAdvances() {
        var session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: { 0 })
        session = answerCorrect(session)
        let pot = session.pots[alice.id] ?? 0

        let next = distributePot(session, rng: { 0 })

        XCTAssertEqual(next.distributedCounts[alice.id], pot)
        XCTAssertEqual(next.pots[alice.id], 0)
        XCTAssertTrue(next.penaltyCounts.isEmpty, "distributing the pot must never add a penalty to the distributor")
        XCTAssertEqual(next.lastOutcome, QuizOutcome(kind: .banked, playerId: alice.id, amount: pot))
        XCTAssertEqual(next.currentPlayerIndex, 1)
        XCTAssertEqual(next.phase, .question)
    }

    func testKeepPotCarriesPotForwardAndAdvances() {
        var session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: { 0 })
        session = answerCorrect(session)
        let pot = session.pots[alice.id] ?? 0

        let next = keepPot(session, rng: { 0 })

        XCTAssertEqual(next.pots[alice.id], pot, "keeping the pot must not reset it")
        XCTAssertNil(next.lastOutcome)
        XCTAssertEqual(next.currentPlayerIndex, 1)
        XCTAssertEqual(next.phase, .question)
    }

    func testKeepPotIsIgnoredOutsideChoicePhase() {
        let session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: { 0 })

        let unchanged = keepPot(session, rng: { 0 })

        XCTAssertEqual(unchanged.turnNumber, session.turnNumber)
        XCTAssertEqual(unchanged.phase, .question)
    }

    func testCurrentPointsRerollsOnEachAdvance() {
        // 3 questions -> shuffle burns 2 rng() calls, then the initial
        // rollPoints burns a 3rd. The 4th call feeds the re-roll inside
        // `advance` triggered by `answerWrong`.
        let rng = makeSequenceRng([0, 0, 0.9, 0.1])
        let session = createQuizSession(questions: makeQuestions(3), players: [alice, bob], rng: rng)
        XCTAssertEqual(session.currentPoints, 3)

        let next = answerWrong(session, rng: rng)

        XCTAssertEqual(next.currentPoints, 1)
        XCTAssertNotEqual(next.currentPoints, session.currentPoints)
    }

    func testQueueExhaustionFinishesSession() {
        var session = createQuizSession(questions: makeQuestions(2), players: [alice, bob], rng: { 0 })
        XCTAssertEqual(session.queue.count, 1)

        session = answerWrong(session, rng: { 0 })
        XCTAssertEqual(session.phase, .question)
        XCTAssertNotNil(session.currentQuestion)

        session = answerWrong(session, rng: { 0 })

        XCTAssertEqual(session.phase, .finished)
        XCTAssertNil(session.currentQuestion)
        XCTAssertTrue(session.queue.isEmpty)
    }

    func testGetCurrentQuizPlayerReturnsNilWhenRosterIsEmpty() {
        let session = createQuizSession(questions: makeQuestions(1), players: [], rng: { 0 })

        XCTAssertNil(getCurrentQuizPlayer(session))
    }
}
