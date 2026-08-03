import Foundation

// ============================================
// QUITTE OU TRINQUE - moteur pur (testé)
// Chaque joueur répond à tour de rôle à une question qui vaut 1 à 3 points
// (tirés au hasard). Bonne réponse : les points rejoignent sa cagnotte, puis
// il choisit - cumuler (la cagnotte grossit, le risque aussi) ou distribuer
// (il donne sa cagnotte en pénalités et repart à zéro). Mauvaise réponse :
// il prend sa cagnotte + les points de la question en pénalités.
// Mirrors `la-taverne/src/core/engine/quizSession.ts`.
// ============================================

public enum QuizPhase: Equatable, Sendable {
    case question
    case choice
    case finished
}

public struct QuizOutcome: Equatable {
    public enum Kind: Equatable {
        case banked
        case busted
    }

    public let kind: Kind
    public let playerId: String
    public let amount: Int

    public init(kind: Kind, playerId: String, amount: Int) {
        self.kind = kind
        self.playerId = playerId
        self.amount = amount
    }
}

/// Value-type engine state for "Quitte ou Trinque". Every transition below
/// returns a new `QuizSessionState`; `Player` is never mutated, so the mode
/// renders its own recap from `penaltyCounts` instead of feeding the shared
/// `RecapView` (which reads `Player.penalties`).
public struct QuizSessionState {
    public var players: [Player]
    public var currentPlayerIndex: Int
    public var queue: [QuizQuestion]
    public var currentQuestion: QuizQuestion?
    /// Valeur de la question en cours (1-3 points).
    public var currentPoints: Int
    /// Cagnotte cumulée par joueur (points en jeu, pas encore bus ni distribués).
    public var pots: [String: Int]
    /// Pénalités réellement prises par joueur (pour le récap).
    public var penaltyCounts: [String: Int]
    /// Pénalités distribuées par joueur (pour la gloire au récap).
    public var distributedCounts: [String: Int]
    /// Dernier événement marquant, affiché en bandeau sur l'écran.
    public var lastOutcome: QuizOutcome?
    public var phase: QuizPhase
    public var turnNumber: Int

    public init(
        players: [Player],
        currentPlayerIndex: Int,
        queue: [QuizQuestion],
        currentQuestion: QuizQuestion?,
        currentPoints: Int,
        pots: [String: Int],
        penaltyCounts: [String: Int],
        distributedCounts: [String: Int],
        lastOutcome: QuizOutcome?,
        phase: QuizPhase,
        turnNumber: Int
    ) {
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.queue = queue
        self.currentQuestion = currentQuestion
        self.currentPoints = currentPoints
        self.pots = pots
        self.penaltyCounts = penaltyCounts
        self.distributedCounts = distributedCounts
        self.lastOutcome = lastOutcome
        self.phase = phase
        self.turnNumber = turnNumber
    }
}

/// Injectable uniform draw in `0..<1`, overridable in tests for determinism.
public typealias QuizRng = () -> Double

private func defaultRng() -> Double {
    Double.random(in: 0..<1)
}

private func shuffle<T>(_ input: [T], rng: QuizRng) -> [T] {
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

private func rollPoints(_ rng: QuizRng) -> Int {
    1 + Int(rng() * 3)
}

private func activePlayers(_ players: [Player]) -> [Player] {
    players.filter(\.active)
}

public func getCurrentQuizPlayer(_ state: QuizSessionState) -> Player? {
    guard state.players.indices.contains(state.currentPlayerIndex) else { return nil }
    return state.players[state.currentPlayerIndex]
}

public func createQuizSession(
    questions: [QuizQuestion],
    players: [Player],
    rng: QuizRng = defaultRng
) -> QuizSessionState {
    var queue = shuffle(questions, rng: rng)
    let currentQuestion = queue.isEmpty ? nil : queue.removeFirst()
    return QuizSessionState(
        players: activePlayers(players),
        currentPlayerIndex: 0,
        queue: queue,
        currentQuestion: currentQuestion,
        currentPoints: rollPoints(rng),
        pots: [:],
        penaltyCounts: [:],
        distributedCounts: [:],
        lastOutcome: nil,
        phase: currentQuestion != nil ? .question : .finished,
        turnNumber: 1
    )
}

private func advance(_ state: QuizSessionState, rng: QuizRng) -> QuizSessionState {
    var next = state
    let nextQuestion = state.queue.first
    next.queue = Array(state.queue.dropFirst())
    next.currentQuestion = nextQuestion
    next.currentPoints = rollPoints(rng)
    next.currentPlayerIndex = state.players.isEmpty ? 0 : (state.currentPlayerIndex + 1) % state.players.count
    next.phase = nextQuestion != nil ? .question : .finished
    next.turnNumber = state.turnNumber + 1
    return next
}

/// Bonne réponse : les points rejoignent la cagnotte, place au choix.
public func answerCorrect(_ state: QuizSessionState) -> QuizSessionState {
    guard let player = getCurrentQuizPlayer(state), state.phase == .question else { return state }
    var next = state
    next.pots[player.id, default: 0] += state.currentPoints
    next.phase = .choice
    next.lastOutcome = nil
    return next
}

/// Mauvaise réponse : le joueur prend sa cagnotte + les points de la question.
public func answerWrong(_ state: QuizSessionState, rng: QuizRng = defaultRng) -> QuizSessionState {
    guard let player = getCurrentQuizPlayer(state), state.phase == .question else { return state }
    let amount = (state.pots[player.id] ?? 0) + state.currentPoints
    var pending = state
    pending.pots[player.id] = 0
    pending.penaltyCounts[player.id, default: 0] += amount
    pending.lastOutcome = QuizOutcome(kind: .busted, playerId: player.id, amount: amount)
    return advance(pending, rng: rng)
}

/// Le joueur distribue sa cagnotte en pénalités et repart à zéro.
public func distributePot(_ state: QuizSessionState, rng: QuizRng = defaultRng) -> QuizSessionState {
    guard let player = getCurrentQuizPlayer(state), state.phase == .choice else { return state }
    let amount = state.pots[player.id] ?? 0
    var pending = state
    pending.pots[player.id] = 0
    pending.distributedCounts[player.id, default: 0] += amount
    pending.lastOutcome = QuizOutcome(kind: .banked, playerId: player.id, amount: amount)
    return advance(pending, rng: rng)
}

/// Le joueur laisse courir sa cagnotte - quitte ou double au prochain tour.
public func keepPot(_ state: QuizSessionState, rng: QuizRng = defaultRng) -> QuizSessionState {
    guard state.phase == .choice else { return state }
    var pending = state
    pending.lastOutcome = nil
    return advance(pending, rng: rng)
}
