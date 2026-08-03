import Foundation

/// Resolves a `PromptItem.targets` value to the concrete player(s) it points
/// to, using the optional attributes a player may have declared on
/// `WelcomeView` (`Player.gender` / `Player.relationship`). Mirrors
/// `la-taverne/src/core/engine/targeting.ts`: pure, testable, injectable RNG.
public enum Targeting {
    /// Injectable RNG so tests can pin the outcome. Defaults to `Double.random(in:)`.
    public typealias Rng = () -> Double

    /// Targets this module knows how to resolve to concrete player(s).
    public static let resolvableTargets: Set<PromptTarget> = [.genderMasculine, .genderFeminine, .pair, .single, .couple]

    /// True when a `targets` value is one this module resolves to a concrete player.
    public static func isResolvable(_ target: PromptTarget?) -> Bool {
        guard let target else { return false }
        return resolvableTargets.contains(target)
    }

    /// Builds a deterministic RNG from a string seed - used so a UI can resolve
    /// the same target for the same turn across re-renders without stashing
    /// state in a view (e.g. seed on `"\(item.id)-\(turnNumber)"`).
    public static func seededRng(_ seed: String) -> Rng {
        let generator = Mulberry32(seed: hash(seed))
        return { generator.next() }
    }

    /// Resolves a content item's `targets` field to the concrete player(s) it
    /// points to.
    ///
    /// Genre et statut relationnel sont des attributs OPTIONNELS déclarés par
    /// les joueurs (voir `Player.gender` / `Player.relationship`) : si
    /// personne à table ne correspond au critère demandé (ex. personne n'a
    /// précisé son genre), on ne bloque JAMAIS la partie - on retombe sur un
    /// joueur actif tiré au hasard. Ne considère que les joueurs actifs ; si
    /// aucun n'est actif (ne devrait pas arriver en session), retombe sur le
    /// roster complet.
    public static func resolve(players: [Player], target: PromptTarget, rng: Rng = { Double.random(in: 0..<1) }) -> [Player] {
        let active = players.filter(\.active)
        let pool = active.isEmpty ? players : active
        guard !pool.isEmpty else { return [] }

        func randomOne() -> [Player] { Array(shuffled(pool, rng: rng).prefix(1)) }
        func matchOrFallback(_ predicate: (Player) -> Bool) -> [Player] {
            let matches = pool.filter(predicate)
            return matches.isEmpty ? randomOne() : Array(shuffled(matches, rng: rng).prefix(1))
        }

        switch target {
        case .genderMasculine:
            return matchOrFallback { $0.gender == .masculine }
        case .genderFeminine:
            return matchOrFallback { $0.gender == .feminine }
        case .single:
            return matchOrFallback { $0.relationship == .single }
        case .couple:
            return matchOrFallback { $0.relationship == .couple }
        case .pair:
            return Array(shuffled(pool, rng: rng).prefix(2))
        case .selfTarget, .chosen, .all:
            // Pas gérés par ce module - fallback gracieux.
            return randomOne()
        }
    }

    private static func shuffled(_ players: [Player], rng: Rng) -> [Player] {
        var out = players
        guard out.count > 1 else { return out }
        for i in stride(from: out.count - 1, to: 0, by: -1) {
            let j = Int(rng() * Double(i + 1))
            out.swapAt(i, min(max(j, 0), i))
        }
        return out
    }

    private static func hash(_ value: String) -> Int32 {
        var hash: Int32 = 0
        for scalar in value.unicodeScalars {
            hash = 31 &* hash &+ Int32(scalar.value)
        }
        return hash
    }

    /// Tiny mulberry32 PRNG - deterministic, good enough for non-cryptographic
    /// UI randomness. Reference class (not a struct) so the seeded generator
    /// closure returned by `seededRng` can mutate its own state across calls.
    ///
    /// Shifts must be logical (unsigned), matching the web reference's `>>>` -
    /// a first port using Swift's arithmetic `>>` on `Int32` sign-extended
    /// negative states and collapsed the distribution (caught by
    /// `TargetingTests.testCanResolveDifferentlyForADifferentSeed`).
    private final class Mulberry32 {
        private var state: Int32

        init(seed: Int32) {
            self.state = seed
        }

        private func unsignedShift(_ value: Int32, _ count: UInt32) -> Int32 {
            Int32(bitPattern: UInt32(bitPattern: value) >> count)
        }

        func next() -> Double {
            state = state &+ 0x6D2B79F5
            var t = state
            t = (t ^ unsignedShift(t, 15)) &* (t | 1)
            t = (t &+ (t ^ unsignedShift(t, 7)) &* (t | 61)) ^ t
            let result = UInt32(bitPattern: t ^ unsignedShift(t, 14))
            return Double(result) / 4294967296.0
        }
    }
}
