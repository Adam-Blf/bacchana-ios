import Foundation

/// A player in a Borderland session. Reference type so the engine can mutate
/// stats in place while views observe the same identity.
public final class Player: Identifiable, Equatable, Codable {
    /// Genre déclaré par le joueur - optionnel, jamais requis pour jouer.
    /// `.other` couvre "autre" ; l'absence de valeur = non précisé.
    /// Mirrors the web's `PlayerGender` ('m' | 'f' | 'x').
    public enum Gender: String, Codable, Sendable, Equatable {
        case masculine = "m"
        case feminine = "f"
        case other = "x"
    }

    /// Statut relationnel déclaré par le joueur - optionnel, jamais requis.
    /// Mirrors the web's `PlayerRelationship` ('single' | 'couple').
    public enum Relationship: String, Codable, Sendable, Equatable {
        case single
        case couple
    }

    public let id: String
    public var name: String
    public var active: Bool
    public var penaltiesStandard: Int
    public var penaltiesMajor: Int
    public var contestsWon: Int
    public var contestsLost: Int
    public var cardsDrawn: Int
    /// Déclaré, optionnel et 100 % local (jamais envoyé en analytics). Sert
    /// uniquement à cibler du contenu (`PromptTarget.genderMasculine` /
    /// `.genderFeminine`, voir `Targeting.swift`).
    public var gender: Gender?
    /// Déclaré, optionnel et 100 % local (jamais envoyé en analytics). Sert
    /// uniquement à cibler du contenu (`PromptTarget.single` / `.couple`).
    public var relationship: Relationship?

    public init(name: String, gender: Gender? = nil, relationship: Relationship? = nil) {
        self.id = "player-\(UUID().uuidString)"
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.active = true
        self.penaltiesStandard = 0
        self.penaltiesMajor = 0
        self.contestsWon = 0
        self.contestsLost = 0
        self.cardsDrawn = 0
        self.gender = gender
        self.relationship = relationship
    }

    public static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }

    /// Applies a resolved penalty to this player's running totals.
    public func apply(_ penalty: PenaltyResult) {
        switch penalty.unit {
        case .majorPenalty:
            penaltiesMajor += penalty.amount
        case .standardPenalty:
            penaltiesStandard += penalty.amount
        }
    }
}

public enum PlayerRotation {
    /// Returns the index of the next active player, circular, skipping inactive players.
    /// Mirrors the web reference `getNextPlayerIndex`.
    public static func nextIndex(from currentIndex: Int, players: [Player]) -> Int {
        guard !players.isEmpty else { return 0 }
        let hasActivePlayer = players.contains { $0.active }
        guard hasActivePlayer else { return 0 }

        var nextIndex = (currentIndex + 1) % players.count
        while !players[nextIndex].active && nextIndex != currentIndex {
            nextIndex = (nextIndex + 1) % players.count
        }
        return nextIndex
    }
}
