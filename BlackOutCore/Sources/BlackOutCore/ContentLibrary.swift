import Foundation

/// Errors surfaced while loading bundled content packs.
public enum ContentLibraryError: Error, Equatable {
    case resourceNotFound(String)
    case decodingFailed(String)
}

/// Loads `ContentPack` JSON files bundled with the app. Free packs are
/// embedded at build time; premium packs are unlocked and fetched separately
/// once entitlements are wired up (see `Billing/`).
public enum ContentLibrary {
    /// Loads and decodes a single pack from the given bundle.
    public static func loadPack(named name: String, in bundle: Bundle) throws -> ContentPack {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Packs") else {
            throw ContentLibraryError.resourceNotFound(name)
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(ContentPack.self, from: data)
        } catch {
            throw ContentLibraryError.decodingFailed("\(name): \(error)")
        }
    }

    /// Loads every free pack shipped in `Packs/`, sorted by title for stable UI ordering.
    public static func loadAllFreePacks(named names: [String], in bundle: Bundle) -> [ContentPack] {
        names.compactMap { try? loadPack(named: $0, in: bundle) }
            .sorted { $0.pack.title < $1.pack.title }
    }
}
