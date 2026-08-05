import Foundation

/// The four French suits of a standard 52-card deck.
public enum Suit: String, Codable, CaseIterable, Sendable {
    case clubs
    case diamonds
    case hearts
    case spades
}

/// The thirteen ranks of a standard 52-card deck, raw value matches display glyph.
public enum Rank: String, Codable, CaseIterable, Sendable {
    case ace = "A"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case ten = "10"
    case jack = "J"
    case queen = "Q"
    case king = "K"

    /// Numeric value used for penalty base amount, matches web reference RANK_VALUES.
    public var numericValue: Int {
        switch self {
        case .ace: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 8
        case .nine: return 9
        case .ten: return 10
        case .jack: return 11
        case .queen: return 12
        case .king: return 13
        }
    }
}

/// Unit of the penalty carried by a card. Store-safe: internal identifiers only,
/// display wording lives in `PenaltyCalculator`.
public enum PenaltyUnit: String, Codable, Sendable {
    /// Major penalty, drawn only on Aces.
    case majorPenalty = "SHOT"
    /// Standard penalty, drawn on every other rank.
    case standardPenalty = "gorgees"
}

/// A single playing card with its precomputed penalty value and unit.
public struct Card: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let suit: Suit
    public let rank: Rank
    public let value: Int
    public let unit: PenaltyUnit

    public init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
        self.value = rank.numericValue
        // CRITICAL RULE ported from borderland.ts: Ace = major penalty, everything else = standard.
        self.unit = rank == .ace ? .majorPenalty : .standardPenalty
        self.id = "\(suit.rawValue)-\(rank.rawValue)"
    }
}
