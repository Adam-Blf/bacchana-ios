import Foundation

/// One wedge of "La Roue du Destin". Mirrors `la-taverne/src/content/roulette.ts`;
/// keep both in sync when the wheel changes.
public struct RouletteSegment: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let detail: String

    public init(id: String, label: String, detail: String) {
        self.id = id
        self.label = label
        self.detail = detail
    }
}

/// La Roulette is an embedded game mode: no content pack, no named player,
/// no recap. 8 segments, store-safe: only abstract penalties, never a named
/// alcohol.
public enum RouletteContent {
    public static let segments: [RouletteSegment] = [
        RouletteSegment(id: "rou-01", label: "1 pénalité", detail: "Le sort est plutôt clément."),
        RouletteSegment(id: "rou-02", label: "2 pénalités", detail: "Un petit rappel à l'ordre."),
        RouletteSegment(id: "rou-03", label: "3 pénalités", detail: "La roue ne fait pas de cadeau."),
        RouletteSegment(id: "rou-04", label: "PÉNALITÉ MAJEURE", detail: "Le pire tirage possible."),
        RouletteSegment(id: "rou-05", label: "Distribue 2", detail: "Choisis deux joueurs qui prennent 1 pénalité chacun."),
        RouletteSegment(id: "rou-06", label: "Immunité", detail: "Aucune pénalité au prochain tour, quoi qu'il arrive."),
        RouletteSegment(id: "rou-07", label: "Tout le monde", detail: "Toute la table prend 1 pénalité."),
        RouletteSegment(id: "rou-08", label: "Rejoue", detail: "Relance la roue immédiatement.")
    ]
}
