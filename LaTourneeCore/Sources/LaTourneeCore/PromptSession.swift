import Foundation

/// A persistent rule still in effect, counted down turn by turn.
public struct ActiveRule: Identifiable, Equatable, Sendable {
    public let id: String
    public let sourceItemID: String
    public let text: String
    public var remainingTurns: Int
}

/// Drives a single pack: draws items without immediate repetition, tracks
/// persistent rules across turns, and interpolates player placeholders.
public final class PromptSession {
    public let pack: ContentPack
    public private(set) var drawPile: [PromptItem]
    public private(set) var discardPile: [PromptItem] = []
    public private(set) var activeRules: [ActiveRule] = []

    public init(pack: ContentPack) {
        self.pack = pack
        self.drawPile = Self.shuffle(pack.items)
    }

    private static func shuffle(_ items: [PromptItem]) -> [PromptItem] {
        var rng = SystemRandomNumberGenerator()
        var shuffled = items
        guard shuffled.count > 1 else { return shuffled }
        for i in stride(from: shuffled.count - 1, to: 0, by: -1) {
            let j = Int.random(in: 0...i, using: &rng)
            shuffled.swapAt(i, j)
        }
        return shuffled
    }

    /// Returns the eligible items given the active player count, filtering
    /// out prompts that require more players than currently present.
    private func eligible(_ items: [PromptItem], playerCount: Int) -> [PromptItem] {
        items.filter { ($0.minPlayers ?? 0) <= playerCount }
    }

    /// Draws the next prompt item, reshuffling the discard pile back in
    /// once the draw pile is exhausted so no item repeats until the pack cycles.
    public func drawNext(playerCount: Int) -> PromptItem? {
        var pool = eligible(drawPile, playerCount: playerCount)
        if pool.isEmpty {
            guard !discardPile.isEmpty else { return nil }
            drawPile = Self.shuffle(discardPile)
            discardPile = []
            pool = eligible(drawPile, playerCount: playerCount)
            guard !pool.isEmpty else { return nil }
        }

        guard let item = pool.first, let index = drawPile.firstIndex(where: { $0.id == item.id }) else {
            return nil
        }
        drawPile.remove(at: index)
        discardPile.append(item)

        if let rule = item.rule, rule.type == .persistent, let duration = rule.durationTurns {
            activeRules.append(ActiveRule(id: UUID().uuidString, sourceItemID: item.id, text: item.text, remainingTurns: duration))
        }

        return item
    }

    /// Decrements every active persistent rule by one turn and drops expired ones.
    public func tickTurn() {
        activeRules = activeRules.compactMap { rule in
            var updated = rule
            updated.remainingTurns -= 1
            return updated.remainingTurns > 0 ? updated : nil
        }
    }

    /// Replaces `{player}` and `{player2}` placeholders with the given names.
    public static func interpolate(_ text: String, player: String, player2: String? = nil) -> String {
        var result = text.replacingOccurrences(of: "{player}", with: player)
        if let player2 {
            result = result.replacingOccurrences(of: "{player2}", with: player2)
        }
        return result
    }
}
