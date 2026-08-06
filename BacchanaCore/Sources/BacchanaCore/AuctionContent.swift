import Foundation

/// One category for "La Criée". Mirrors `bacchana-site/src/content/auction.ts`;
/// keep both in sync when the theme list changes.
public struct AuctionTheme: Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

/// La Criée is an embedded game mode: no content pack, no named player,
/// no recap. 50 categories, store-safe: never a named alcohol.
public enum AuctionContent {
    public static let auctionThemes: [AuctionTheme] = [
        AuctionTheme(id: "au-01", text: "Des capitales européennes"),
        AuctionTheme(id: "au-02", text: "Des films avec des super-héros"),
        AuctionTheme(id: "au-03", text: "Des marques de voitures"),
        AuctionTheme(id: "au-04", text: "Des joueurs de foot français"),
        AuctionTheme(id: "au-05", text: "Des animaux qui vivent dans la savane"),
        AuctionTheme(id: "au-06", text: "Des chansons de Disney"),
        AuctionTheme(id: "au-07", text: "Des sortes de fromages"),
        AuctionTheme(id: "au-08", text: "Des séries Netflix"),
        AuctionTheme(id: "au-09", text: "Des pays d'Afrique"),
        AuctionTheme(id: "au-10", text: "Des prénoms commençant par la lettre M"),
        AuctionTheme(id: "au-11", text: "Des métiers qui font peur"),
        AuctionTheme(id: "au-12", text: "Des choses qu'on trouve dans une trousse"),
        AuctionTheme(id: "au-13", text: "Des sports olympiques"),
        AuctionTheme(id: "au-14", text: "Des pizzas différentes"),
        AuctionTheme(id: "au-15", text: "Des rappeurs ou rappeuses francophones"),
        AuctionTheme(id: "au-16", text: "Des personnages de dessins animés"),
        AuctionTheme(id: "au-17", text: "Des villes françaises de plus de 100 000 habitants"),
        AuctionTheme(id: "au-18", text: "Des marques de vêtements"),
        AuctionTheme(id: "au-19", text: "Des choses qu'on emporte à la plage"),
        AuctionTheme(id: "au-20", text: "Des instruments de musique"),
        AuctionTheme(id: "au-21", text: "Des excuses classiques pour un retard"),
        AuctionTheme(id: "au-22", text: "Des films d'horreur"),
        AuctionTheme(id: "au-23", text: "Des mots qui riment avec « soirée »"),
        AuctionTheme(id: "au-24", text: "Des émissions de télé-réalité"),
        AuctionTheme(id: "au-25", text: "Des sortes de pâtes"),
        AuctionTheme(id: "au-26", text: "Des pays où il fait (très) chaud"),
        AuctionTheme(id: "au-27", text: "Des choses jaunes"),
        AuctionTheme(id: "au-28", text: "Des applis présentes sur presque tous les téléphones"),
        AuctionTheme(id: "au-29", text: "Des super-pouvoirs"),
        AuctionTheme(id: "au-30", text: "Des choses qu'on fait semblant d'aimer en famille"),
        AuctionTheme(id: "au-31", text: "Des animaux marins"),
        AuctionTheme(id: "au-32", text: "Des jeux de société"),
        AuctionTheme(id: "au-33", text: "Des acteurs ou actrices français"),
        AuctionTheme(id: "au-34", text: "Des choses dans un sac à main"),
        AuctionTheme(id: "au-35", text: "Des langues parlées dans le monde"),
        AuctionTheme(id: "au-36", text: "Des desserts français"),
        AuctionTheme(id: "au-37", text: "Des groupes ou chanteurs des années 80"),
        AuctionTheme(id: "au-38", text: "Des raisons de quitter une soirée"),
        AuctionTheme(id: "au-39", text: "Des choses qui se mangent crues"),
        AuctionTheme(id: "au-40", text: "Des monuments célèbres dans le monde"),
        AuctionTheme(id: "au-41", text: "Des mots d'argot pour dire « argent »"),
        AuctionTheme(id: "au-42", text: "Des sports qui se jouent avec une balle ou un ballon"),
        AuctionTheme(id: "au-43", text: "Des personnages de Harry Potter"),
        AuctionTheme(id: "au-44", text: "Des choses qu'on trouve dans une cuisine"),
        AuctionTheme(id: "au-45", text: "Des marques de céréales ou de biscuits"),
        AuctionTheme(id: "au-46", text: "Des îles"),
        AuctionTheme(id: "au-47", text: "Des choses qui piquent"),
        AuctionTheme(id: "au-48", text: "Des films romantiques"),
        AuctionTheme(id: "au-49", text: "Des choses qu'on fait avant de dormir"),
        AuctionTheme(id: "au-50", text: "Des animaux plus petits qu'une main")
    ]

    /// Draws a random theme, excluding the previous one when the pool allows it
    /// so consecutive rounds do not repeat. Mirrors `pickTheme` in
    /// `AuctionScreen.tsx`.
    public static func pickTheme(from pool: [AuctionTheme] = auctionThemes, excluding: String?) -> AuctionTheme {
        let candidates = pool.filter { $0.id != excluding }
        let source = candidates.isEmpty ? pool : candidates
        return source[Int.random(in: 0..<source.count)]
    }
}
