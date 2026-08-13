import Foundation

/// A single secret accusation, either written by a player or embedded from
/// `TribunalContent.tribunalCharges` when the table skips collection.
public struct TribunalAccusation: Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String
    /// `nil` when the accusation comes from the app's built-in deck.
    public let authorID: String?

    public init(id: String = UUID().uuidString, text: String, authorID: String?) {
        self.id = id
        self.text = text
        self.authorID = authorID
    }
}

/// Mirrors the web reference's `Phase` union in `TribunalScreen.tsx`.
public enum TribunalPhase: Equatable, Sendable {
    case intro
    case collectHandoff
    case collectWrite
    case defense
    case vote
    case finished
}

public enum TribunalVerdict: Equatable, Sendable {
    case guilty
    case innocent
}

/// Pure, view-independent engine for "Le Pilori". Mirrors
/// `bacchana-site/src/components/screens/TribunalScreen.tsx`: it never mutates
/// `Player` and keeps its own local `penaltyCounts` keyed by player id, so
/// the mode renders its own recap instead of feeding the shared `RecapView`
/// (which reads `Player.penalties`).
public final class TribunalSession {
    /// Active roster for this trial session, snapshotted at creation.
    public let players: [Player]
    public private(set) var pool: [TribunalAccusation] = []
    public private(set) var current: TribunalAccusation?
    public private(set) var accused: Player?
    public private(set) var verdict: TribunalVerdict?
    public private(set) var penaltyCounts: [String: Int] = [:]
    public private(set) var trialsPlayed = 0

    private let randomIndex: (Int) -> Int

    /// - Parameter randomIndex: injected `0..<bound -> Int` picker, defaults
    ///   to `Int.random(in:)`, overridable in tests for determinism.
    public init(players: [Player], randomIndex: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }) {
        self.players = players.filter(\.active)
        self.randomIndex = randomIndex
    }

    private func pickRandom<T>(_ items: [T]) -> T? {
        guard !items.isEmpty else { return nil }
        return items[randomIndex(items.count)]
    }

    /// Excludes the accusation's author (if any) from the accused pool;
    /// falls back to the full active roster if that empties it out. Mirrors
    /// the web `pickAccused`.
    public func pickAccused(excluding authorID: String?) -> Player? {
        let eligible = players.filter { $0.id != authorID }
        let candidates = eligible.isEmpty ? players : eligible
        return pickRandom(candidates)
    }

    /// Starts a trial by drawing one accusation at random from the given
    /// pool, or from `TribunalContent.tribunalCharges` when the pool is
    /// empty (the table chose the app's own charges).
    public func startTrial(from accusations: [TribunalAccusation]) {
        let source = accusations.isEmpty
            ? TribunalContent.tribunalCharges.map { TribunalAccusation(text: $0.text, authorID: nil) }
            : accusations
        guard let accusation = pickRandom(source) else { return }
        current = accusation
        accused = pickAccused(excluding: accusation.authorID)
        pool = accusations.filter { $0.id != accusation.id }
        verdict = nil
    }

    /// Resolves the vote: a strict majority of guilty votes adds 1 local
    /// penalty to the accused. A tie resolves as innocent, mirroring the
    /// web reference (`votesGuilty > votesInnocent`).
    @discardableResult
    public func resolveVerdict(votesGuilty: Int, votesInnocent: Int) -> TribunalVerdict? {
        guard let accused else { return nil }
        let guilty = votesGuilty > votesInnocent
        verdict = guilty ? .guilty : .innocent
        trialsPlayed += 1
        if guilty {
            penaltyCounts[accused.id, default: 0] += 1
        }
        return verdict
    }

    /// The current charge with `{player}` replaced by the accused's name.
    public var chargeText: String {
        guard let current, let accused else { return "" }
        return PromptSession.interpolate(current.text, player: accused.name)
    }
}
