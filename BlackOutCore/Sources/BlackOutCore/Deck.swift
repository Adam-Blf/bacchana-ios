import Foundation

/// Pure deck construction and shuffling. No storage, no UI, fully testable.
public enum Deck {
    /// Creates a standard, ordered 52-card deck.
    public static func createDeck() -> [Card] {
        var deck: [Card] = []
        deck.reserveCapacity(52)
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        return deck
    }

    /// Fisher-Yates shuffle. Returns a new array, does not mutate the input.
    public static func shuffled(_ deck: [Card], using generator: inout some RandomNumberGenerator) -> [Card] {
        var shuffled = deck
        guard shuffled.count > 1 else { return shuffled }
        for i in stride(from: shuffled.count - 1, to: 0, by: -1) {
            let j = Int.random(in: 0...i, using: &generator)
            shuffled.swapAt(i, j)
        }
        return shuffled
    }

    /// Convenience overload using the system random source.
    public static func shuffled(_ deck: [Card]) -> [Card] {
        var rng = SystemRandomNumberGenerator()
        return shuffled(deck, using: &rng)
    }
}
