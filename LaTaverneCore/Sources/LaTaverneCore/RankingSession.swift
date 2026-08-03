import Foundation

// ============================================
// LE TABLEAU D'HONNEUR - moteur pur (testé)
// Un juge découvre une question secrète et classe les autres joueurs selon
// elle. Le groupe voit le podium et doit retrouver la vraie question parmi
// quatre propositions. Trouvé : le juge prend les pénalités. Raté : tout le
// groupe en prend une chacun.
// Mirrors `la-taverne/src/core/engine/rankingSession.ts`.
// ============================================

public enum RankingPhase: Equatable, Sendable {
    case handoff
    case judging
    case `return`
    case guessing
    case reveal
    case finished
}

public let rankingJudgePenalty = 3
public let rankingGroupPenalty = 1

public struct RankingRound: Equatable {
    public let question: RankingQuestion
    /// 4 propositions mélangées, dont la vraie question.
    public let choices: [RankingQuestion]

    public init(question: RankingQuestion, choices: [RankingQuestion]) {
        self.question = question
        self.choices = choices
    }
}

/// Value-type engine state for "Le Tableau d'Honneur". Every transition below
/// returns a new `RankingSessionState`; `Player` is never mutated, so the mode
/// renders its own recap from `penaltyCounts` instead of feeding the shared
/// `RecapView` (which reads `Player.penalties`).
public struct RankingSessionState {
    public var players: [Player]
    public var allQuestions: [RankingQuestion]
    public var queue: [RankingQuestion]
    public var judgeIndex: Int
    public var roundNumber: Int
    public var round: RankingRound?
    /// Ids des joueurs classés par le juge, du haut du podium vers le bas.
    public var ranked: [String]
    public var guessedId: String?
    public var phase: RankingPhase
    public var penaltyCounts: [String: Int]

    public init(
        players: [Player],
        allQuestions: [RankingQuestion],
        queue: [RankingQuestion],
        judgeIndex: Int,
        roundNumber: Int,
        round: RankingRound?,
        ranked: [String],
        guessedId: String?,
        phase: RankingPhase,
        penaltyCounts: [String: Int]
    ) {
        self.players = players
        self.allQuestions = allQuestions
        self.queue = queue
        self.judgeIndex = judgeIndex
        self.roundNumber = roundNumber
        self.round = round
        self.ranked = ranked
        self.guessedId = guessedId
        self.phase = phase
        self.penaltyCounts = penaltyCounts
    }
}

/// Injectable uniform draw in `0..<1`, overridable in tests for determinism.
public typealias RankingRng = () -> Double

public func defaultRankingRng() -> Double {
    Double.random(in: 0..<1)
}

private func shuffle<T>(_ input: [T], rng: RankingRng) -> [T] {
    var arr = input
    guard arr.count > 1 else { return arr }
    var index = arr.count - 1
    while index > 0 {
        let swapIndex = Int(rng() * Double(index + 1))
        arr.swapAt(index, swapIndex)
        index -= 1
    }
    return arr
}

public func getJudge(_ state: RankingSessionState) -> Player? {
    guard state.players.indices.contains(state.judgeIndex) else { return nil }
    return state.players[state.judgeIndex]
}

public func getContestants(_ state: RankingSessionState) -> [Player] {
    let judge = getJudge(state)
    return state.players.filter { $0.id != judge?.id }
}

private func buildRound(
    question: RankingQuestion,
    allQuestions: [RankingQuestion],
    rng: RankingRng
) -> RankingRound {
    let decoys = Array(
        shuffle(allQuestions.filter { $0.id != question.id }, rng: rng).prefix(3)
    )
    return RankingRound(question: question, choices: shuffle([question] + decoys, rng: rng))
}

public func createRankingSession(
    questions: [RankingQuestion],
    players: [Player],
    rng: RankingRng = defaultRankingRng
) -> RankingSessionState {
    var queue = shuffle(questions, rng: rng)
    let first = queue.isEmpty ? nil : queue.removeFirst()
    return RankingSessionState(
        players: players.filter(\.active),
        allQuestions: questions,
        queue: queue,
        judgeIndex: 0,
        roundNumber: 1,
        round: first.map { buildRound(question: $0, allQuestions: questions, rng: rng) },
        ranked: [],
        guessedId: nil,
        phase: first != nil ? .handoff : .finished,
        penaltyCounts: [:]
    )
}

/// Le juge a le téléphone en main : place au classement secret.
public func startJudging(_ state: RankingSessionState) -> RankingSessionState {
    guard state.phase == .handoff else { return state }
    var next = state
    next.phase = .judging
    return next
}

/// Ajoute (ou retire) un joueur au podium du juge, dans l'ordre des taps.
public func toggleRanked(_ state: RankingSessionState, playerId: String) -> RankingSessionState {
    guard state.phase == .judging else { return state }
    let judge = getJudge(state)
    guard playerId != judge?.id else { return state }
    var next = state
    if let index = next.ranked.firstIndex(of: playerId) {
        next.ranked.remove(at: index)
    } else {
        next.ranked.append(playerId)
    }
    return next
}

/// Le juge valide son podium et rend le téléphone à la table.
public func confirmRanking(_ state: RankingSessionState) -> RankingSessionState {
    guard state.phase == .judging else { return state }
    guard state.ranked.count == getContestants(state).count else { return state }
    var next = state
    next.phase = .return
    return next
}

/// Le téléphone est de retour au centre : le groupe découvre le podium.
public func startGuessing(_ state: RankingSessionState) -> RankingSessionState {
    guard state.phase == .return else { return state }
    var next = state
    next.phase = .guessing
    return next
}

/// Le groupe choisit une proposition ; les pénalités tombent immédiatement.
public func guessQuestion(_ state: RankingSessionState, questionId: String) -> RankingSessionState {
    guard state.phase == .guessing, let round = state.round else { return state }
    let judge = getJudge(state)
    let correct = questionId == round.question.id
    var penaltyCounts = state.penaltyCounts
    if correct, let judge {
        penaltyCounts[judge.id, default: 0] += rankingJudgePenalty
    } else {
        for player in getContestants(state) {
            penaltyCounts[player.id, default: 0] += rankingGroupPenalty
        }
    }
    var next = state
    next.guessedId = questionId
    next.penaltyCounts = penaltyCounts
    next.phase = .reveal
    return next
}

/// Manche suivante : le rôle de juge tourne, nouvelle question secrète.
public func nextRound(_ state: RankingSessionState, rng: RankingRng = defaultRankingRng) -> RankingSessionState {
    guard state.phase == .reveal else { return state }
    var queue = state.queue
    let next = queue.isEmpty ? nil : queue.removeFirst()
    var pending = state
    pending.queue = queue
    pending.judgeIndex = state.players.isEmpty ? 0 : (state.judgeIndex + 1) % state.players.count
    pending.roundNumber = state.roundNumber + 1
    pending.round = next.map { buildRound(question: $0, allQuestions: state.allQuestions, rng: rng) }
    pending.ranked = []
    pending.guessedId = nil
    pending.phase = next != nil ? .handoff : .finished
    return pending
}
