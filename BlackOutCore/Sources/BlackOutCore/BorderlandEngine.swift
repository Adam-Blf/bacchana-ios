import Foundation

/// Drives a full Borderland session: deck, active player rotation, and
/// contest resolution. Pure logic, no persistence, no UI.
public final class BorderlandEngine {
    public private(set) var players: [Player]
    public private(set) var drawPile: [Card]
    public private(set) var discardPile: [Card] = []
    public private(set) var currentPlayerIndex: Int
    public private(set) var activeContest: ContestState?

    public init(players: [Player], shuffledDeck: [Card] = Deck.shuffled(Deck.createDeck())) {
        precondition(!players.isEmpty, "BorderlandEngine requires at least one player")
        self.players = players
        self.drawPile = shuffledDeck
        self.currentPlayerIndex = 0
        self.activeContest = nil
    }

    public var currentPlayer: Player {
        players[currentPlayerIndex]
    }

    /// Draws the next card for the current player, reshuffling the discard
    /// pile back in if the draw pile is exhausted.
    @discardableResult
    public func drawCard() -> Card? {
        if drawPile.isEmpty {
            guard !discardPile.isEmpty else { return nil }
            drawPile = Deck.shuffled(discardPile)
            discardPile = []
        }
        guard let card = drawPile.popLast() else { return nil }
        discardPile.append(card)
        currentPlayer.cardsDrawn += 1
        return card
    }

    /// Starts a contest between the current player and a chosen opponent.
    public func startContest(against opponent: Player) {
        activeContest = ContestState(challenger: currentPlayer.id, opponent: opponent.id)
    }

    /// Escalates the active contest by one level, capped at `.quadruple`.
    public func escalateContest() {
        guard var contest = activeContest, contest.level != .quadruple else { return }
        let nextRaw = min(contest.level.rawValue + 1, ContestLevel.quadruple.rawValue)
        contest.level = ContestLevel(rawValue: nextRaw) ?? .quadruple
        activeContest = contest
    }

    /// Resolves the given card penalty onto the loser of the current contest
    /// (or the current player if no contest is active), then advances turn.
    @discardableResult
    public func resolvePenalty(for card: Card, loser: Player) -> PenaltyResult {
        let level = activeContest?.level ?? .none
        let penalty = PenaltyCalculator.calculate(for: card, level: level)
        loser.apply(penalty)
        if activeContest != nil {
            let winner = players.first { $0.id != loser.id }
            winner?.contestsWon += 1
            loser.contestsLost += 1
        }
        activeContest = nil
        advanceTurn()
        return penalty
    }

    /// Moves to the next active player, skipping inactive ones.
    public func advanceTurn() {
        currentPlayerIndex = PlayerRotation.nextIndex(from: currentPlayerIndex, players: players)
    }
}
