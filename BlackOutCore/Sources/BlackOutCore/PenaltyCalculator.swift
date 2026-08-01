import Foundation

/// Resolved penalty ready to be displayed and applied to a player.
/// Wording is store-safe: the app hands out abstract penalties, the group
/// decides in real life what a penalty is worth.
public struct PenaltyResult: Equatable, Sendable {
    public let amount: Int
    public let unit: PenaltyUnit
    public let displayText: String
}

public enum PenaltyCalculator {
    /// Calculates the final penalty for a base amount scaled by a contest level.
    /// The unit never changes, only the amount is multiplied.
    public static func calculate(baseAmount: Int, level: ContestLevel, unit: PenaltyUnit) -> PenaltyResult {
        let amount = baseAmount * level.multiplier

        let displayText: String
        switch unit {
        case .majorPenalty:
            displayText = amount > 1 ? "PÉNALITÉ MAJEURE x\(amount)" : "PÉNALITÉ MAJEURE"
        case .standardPenalty:
            displayText = amount > 1 ? "\(amount) pénalités" : "\(amount) pénalité"
        }

        return PenaltyResult(amount: amount, unit: unit, displayText: displayText)
    }

    /// Convenience overload starting from a drawn card.
    public static func calculate(for card: Card, level: ContestLevel) -> PenaltyResult {
        calculate(baseAmount: card.value, level: level, unit: card.unit)
    }
}
