import Foundation

/// Supported prompt game modes. Raw values match `content.schema.json`.
public enum GameMode: String, Codable, CaseIterable, Sendable {
    case borderland
    case picolo
    case truthOrDare
    case neverHaveIEver
    case whoAmong
    case wouldYouRather
    case itsA10But
    case sevenSeconds
    case tribunal
    case roulette
}

public enum Intensity: String, Codable, Sendable {
    case soft
    case medium
    case hot
    case chaos
}

public enum PromptRuleType: String, Codable, Sendable {
    case instant
    case persistent
    case role
}

public enum PromptTarget: String, Codable, Sendable {
    case selfTarget = "self"
    case chosen
    case all
    case genderMasculine = "gender-m"
    case genderFeminine = "gender-f"
    case pair
}

public struct PromptRule: Codable, Equatable, Sendable {
    public let type: PromptRuleType
    public let durationTurns: Int?
}

public struct PromptPenalty: Codable, Equatable, Sendable {
    public let sips: Int?
    public let shots: Int?
}

public struct PromptItem: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String
    public let textAlt: String?
    public let penalty: PromptPenalty?
    public let rule: PromptRule?
    public let targets: PromptTarget?
    public let tags: [String]?
    public let minPlayers: Int?
}

public struct PackMeta: Codable, Equatable, Sendable {
    public let id: String
    public let mode: GameMode
    public let lang: String
    public let title: String
    public let subtitle: String?
    public let premium: Bool
    public let minPlayers: Int?
    public let intensity: Intensity?
}

public struct ContentPack: Codable, Identifiable, Equatable, Sendable {
    public let schemaVersion: Int
    public let pack: PackMeta
    public let items: [PromptItem]

    public var id: String { pack.id }
}
