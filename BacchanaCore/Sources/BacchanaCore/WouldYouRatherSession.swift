import Foundation

// ============================================
// TU PRÉFÈRES - moteur pur (testé)
// Un dilemme A ou B s'affiche, le téléphone tourne, chaque joueur actif tape
// son camp. Au reveal, la minorité est pénalisée (pénalité locale) ; égalité
// parfaite ou vote unanime : personne ne l'est.
// Mirrors `bacchana-site/src/core/engine/wouldYouRatherSession.ts`.
// ============================================

public enum WouldYouRatherPhase: Equatable, Sendable {
    case voting
    case reveal
    case finished
}

/// The two sides of a dilemma.
public enum WouldYouRatherSide: String, Equatable, Sendable {
    case optionA
    case optionB
}

/// Nombre de pénalités appliquées à chaque joueur de la minorité au reveal.
public let minorityPenalty = 1

/// Value-type engine state for "Tu préfères". Every transition below returns
/// a new `WouldYouRatherSessionState`; `Player` is never mutated, so the mode
/// renders its own recap from `penaltyCounts` instead of feeding the shared
/// `RecapView` (which reads `Player.penalties`).
public struct WouldYouRatherSessionState {
    public var players: [Player]
    public var queue: [WouldYouRatherQuestion]
    public var currentQuestion: WouldYouRatherQuestion?
    /// Vote du joueur courant pour la manche en cours.
    public var votes: [String: WouldYouRatherSide]
    /// Pénalités réellement prises par joueur (pour le récap).
    public var penaltyCounts: [String: Int]
    public var phase: WouldYouRatherPhase
    public var roundNumber: Int

    public init(
        players: [Player],
        queue: [WouldYouRatherQuestion],
        currentQuestion: WouldYouRatherQuestion?,
        votes: [String: WouldYouRatherSide],
        penaltyCounts: [String: Int],
        phase: WouldYouRatherPhase,
        roundNumber: Int
    ) {
        self.players = players
        self.queue = queue
        self.currentQuestion = currentQuestion
        self.votes = votes
        self.penaltyCounts = penaltyCounts
        self.phase = phase
        self.roundNumber = roundNumber
    }
}

/// Injectable uniform draw in `0..<1`, overridable in tests for determinism.
public typealias WouldYouRatherRng = () -> Double

public func defaultWouldYouRatherRng() -> Double {
    Double.random(in: 0..<1)
}

private func shuffle<T>(_ input: [T], rng: WouldYouRatherRng) -> [T] {
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

/// Creates a fresh session: shuffles the deck, keeps only active players, and
/// seats the first question in `.voting`.
public func createWouldYouRatherSession(
    questions: [WouldYouRatherQuestion],
    players: [Player],
    rng: WouldYouRatherRng = defaultWouldYouRatherRng
) -> WouldYouRatherSessionState {
    var queue = shuffle(questions, rng: rng)
    let currentQuestion = queue.isEmpty ? nil : queue.removeFirst()
    return WouldYouRatherSessionState(
        players: players.filter(\.active),
        queue: queue,
        currentQuestion: currentQuestion,
        votes: [:],
        penaltyCounts: [:],
        phase: currentQuestion != nil ? .voting : .finished,
        roundNumber: 1
    )
}

/// Records (or overwrites) a player's vote for the current round. A no-op
/// outside `.voting` or for a player who is not part of the session.
public func castVote(_ state: WouldYouRatherSessionState, playerId: String, side: WouldYouRatherSide) -> WouldYouRatherSessionState {
    guard state.phase == .voting, state.players.contains(where: { $0.id == playerId }) else { return state }
    var next = state
    next.votes[playerId] = side
    return next
}

/// `true` once every active player has cast a vote for the current round.
public func allVoted(_ state: WouldYouRatherSessionState) -> Bool {
    guard !state.players.isEmpty else { return false }
    return state.players.allSatisfy { state.votes[$0.id] != nil }
}

/// Counts votes per side among the players who actually voted.
public func countVotes(_ state: WouldYouRatherSessionState) -> (optionA: Int, optionB: Int) {
    var countA = 0
    var countB = 0
    for side in state.votes.values {
        switch side {
        case .optionA: countA += 1
        case .optionB: countB += 1
        }
    }
    return (countA, countB)
}

/// The side that lost the vote, or `nil` on a perfect tie or a unanimous
/// vote (nobody is penalised in either case).
public func minoritySide(_ state: WouldYouRatherSessionState) -> WouldYouRatherSide? {
    let counts = countVotes(state)
    guard counts.optionA != counts.optionB else { return nil }
    guard counts.optionA > 0, counts.optionB > 0 else { return nil }
    return counts.optionA < counts.optionB ? .optionA : .optionB
}

/// Resolves the current round: the minority side takes `minorityPenalty`
/// pénalités each, then moves to `.reveal`. A no-op outside `.voting`.
public func revealVotes(_ state: WouldYouRatherSessionState) -> WouldYouRatherSessionState {
    guard state.phase == .voting else { return state }
    var next = state
    if let losingSide = minoritySide(state) {
        for player in state.players where state.votes[player.id] == losingSide {
            next.penaltyCounts[player.id, default: 0] += minorityPenalty
        }
    }
    next.phase = .reveal
    return next
}

/// Moves on to the next question, or `.finished` once the queue is empty.
/// A no-op outside `.reveal`.
public func nextRound(_ state: WouldYouRatherSessionState) -> WouldYouRatherSessionState {
    guard state.phase == .reveal else { return state }
    var next = state
    let nextQuestion = state.queue.first
    next.queue = Array(state.queue.dropFirst())
    next.currentQuestion = nextQuestion
    next.votes = [:]
    next.phase = nextQuestion != nil ? .voting : .finished
    next.roundNumber = state.roundNumber + 1
    return next
}
