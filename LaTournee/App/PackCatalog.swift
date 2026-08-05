import Foundation
import LaTourneeCore

/// Metadata-only entry for the Hub grid, decoded from `premium-catalog.json`.
/// Premium entries never carry `items`, so a locked pack ships with zero
/// spoiler content in the free build.
struct PackCatalogEntry: Codable, Identifiable {
    let id: String
    let mode: GameMode
    let lang: String
    let title: String
    let subtitle: String?
    let premium: Bool
    let minPlayers: Int?
    let intensity: Intensity?
}

private struct PackCatalogFile: Codable {
    let schemaVersion: Int
    let packs: [PackCatalogEntry]
}

enum PackCatalog {
    /// Loads the full catalog (free + locked premium) from the app bundle.
    static func loadAll(in bundle: Bundle = .main) -> [PackCatalogEntry] {
        guard let url = bundle.url(forResource: "premium-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(PackCatalogFile.self, from: data) else {
            return []
        }
        return file.packs
    }

    /// Loads the full pack (metadata + items) for a free pack id.
    static func loadFullPack(id: String, in bundle: Bundle = .main) -> ContentPack? {
        try? ContentLibrary.loadPack(named: id, in: bundle)
    }
}
