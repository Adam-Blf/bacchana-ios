import Foundation

/// Outcome level of a contest (duel) between two players, drives the penalty multiplier.
/// Mirrors the web reference `CONTEST_MULTIPLIERS` mapping {0:1, 1:1, 2:2, 3:4}.
public enum ContestLevel: Int, CaseIterable, Codable, Sendable {
    case none = 0
    case tie = 1
    case double = 2
    case quadruple = 3

    public var multiplier: Int {
        switch self {
        case .none: return 1
        case .tie: return 1
        case .double: return 2
        case .quadruple: return 4
        }
    }
}

/// State of an in-progress contest between two players over a drawn card.
public struct ContestState: Equatable {
    public let challenger: Player.ID
    public let opponent: Player.ID
    public var level: ContestLevel

    public init(challenger: Player.ID, opponent: Player.ID, level: ContestLevel = .none) {
        self.challenger = challenger
        self.opponent = opponent
        self.level = level
    }
}
