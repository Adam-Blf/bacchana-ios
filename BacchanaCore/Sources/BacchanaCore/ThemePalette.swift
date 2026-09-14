import Foundation

/// Raw Bacchana design tokens - platform-agnostic (no SwiftUI/UIKit import),
/// so both the app's `Theme.Color` (SwiftUI, `Bacchana/Theme/Theme.swift`)
/// and the CI contrast guard (`BacchanaTests/ContrastGuardTests.swift`) build
/// on the exact same source of truth. Mirrors
/// `bacchana-site/src/styles/tokens.css` and `docs/DESIGN_TOKENS.md` - never
/// edit a hex value here without updating both, and never let `Theme.swift`
/// hardcode a hex literal that duplicates one of these.
///
/// ALIGNE SUR LE WEB LE 2026-09-14. Le web etait passe au pourpre le
/// 2026-08-30 (direction « Tirage de nuit ») ; ce fichier etait reste a
/// l'orange - accent 0xFA5600 contre 0x5B2C87, encre 0x111111 contre
/// 0x2A1140. La consigne ci-dessus etait juste ; c'est qu'elle ne soit
/// QU'UNE CONSIGNE qui a laisse passer. Tant que ces valeurs sont recopiees
/// a la main, elles rederiveront : les generer depuis `tokens.css` est la
/// seule correction durable, et elle reste a faire.
public enum ThemePalette {
    /// One token's value in each theme. Some tokens never change between
    /// themes (e.g. `tileInk`, `cardFace`) - `.fixed` expresses that at the
    /// call site so a future accidental "themed" edit is obvious in review.
    public struct Token: Sendable, Equatable {
        public let light: UInt32
        public let dark: UInt32

        public static func dynamic(light: UInt32, dark: UInt32) -> Token {
            Token(light: light, dark: dark)
        }

        public static func fixed(_ hex: UInt32) -> Token {
            Token(light: hex, dark: hex)
        }
    }

    // MARK: - Surfaces (elevation ramp)

    /// Le theme sombre n'assombrit pas le creme : il POSE L'APLAT POURPRE. Le
    /// fond, le releve et la surface valent donc la meme teinte, et l'elevation
    /// se lit au filet - le systeme n'a plus d'ombre portee.
    public static let background = Token.dynamic(light: 0xFFF9F0, dark: 0x5B2C87)
    public static let backgroundRaised = Token.dynamic(light: 0xF3E9DC, dark: 0x5B2C87)
    public static let surface = Token.dynamic(light: 0xFFFDF8, dark: 0x5B2C87)
    public static let surfaceElevated = Token.dynamic(light: 0xF3E9DC, dark: 0x4C2371)

    // MARK: - Ink (inverts with theme: dark in light mode, cream in dark mode)

    public static let ink = Token.dynamic(light: 0x2A1140, dark: 0xFFF9F0)
    public static let inkSecondary = Token.dynamic(light: 0x4A2470, dark: 0xDCCFEA)
    public static let inkMuted = Token.dynamic(light: 0x6B4A8C, dark: 0xC0AAD6)

    // MARK: - Brand accent ("neon" keeps its historical token name)

    /// L'accent. `neon` garde son nom historique de jeton, mais ce n'est plus
    /// un orange : c'est la SURIMPRESSION du web, pourpre sur fond clair et
    /// jaune sur fond pourpre. Contrairement a l'orange qu'il remplace, il ne
    /// reste donc PAS clair dans les deux themes - l'encre posee dessus est
    /// `onAccent`, jamais `tileInk`.
    public static let neon = Token.dynamic(light: 0x5B2C87, dark: 0xFFD029)
    public static let neonDeep = Token.dynamic(light: 0x4C2371, dark: 0xE8B81C)
    public static let neonSoft = Token.dynamic(light: 0x7E49AE, dark: 0xFFE07A)
    public static let orangeInk = Token.dynamic(light: 0x5B2C87, dark: 0xFFD029)

    // MARK: - Les quatre ambres - FIXES dans les deux themes

    /// Une ROTATION, pas quatre roles : ils se distribuent par index, aucun ne
    /// porte de sens propre. La seule encre admise par-dessus est `tileInk`.
    ///
    /// Ils s'appelaient popYellow, popPink, popBlue et popLime jusqu'au
    /// 2026-09-14 ; trois de ces noms mentaient sur la teinte depuis le
    /// passage au pourpre, et un nom qui ment survit plus longtemps qu'une
    /// couleur qui change. Memes noms que `--color-aplat-1` a `-4` cote web,
    /// et fixes comme lui : l'encre posee dessus ne suit pas le theme, donc le
    /// fond ne le peut pas non plus.
    public static let aplat1 = Token.fixed(0xFFD029)
    public static let aplat2 = Token.fixed(0xFFB020)
    public static let aplat3 = Token.fixed(0xFFE07A)
    public static let aplat4 = Token.fixed(0xE8B81C)

    // MARK: - Fixed tokens: physical card / tile objects, never themed

    public static let cardFace = Token.fixed(0xFFF9F0)
    public static let cardInk = Token.fixed(0x2A1140)
    /// Playing-card pip red. Reserved for content posed on `cardFace`
    /// (hearts/diamonds pips, roulette/tribunal result labels) - never a
    /// semantic "error" UI color, see `danger` below.
    public static let cardRed = Token.fixed(0x5B2C87)
    /// Encre fixe pour tout texte/icone/bordure pose sur un des quatre AMBRES
    /// (`aplat1` a `aplat4`), qui restent clairs dans les deux themes - elle ne
    /// doit jamais suivre le theme. Numeriquement identique a `cardInk` (meme
    /// raisonnement : un fond fixe), gardee comme jeton nomme distinct pour
    /// coller a `docs/DESIGN_TOKENS.md` section 2bis et `--color-tile-ink`.
    ///
    /// Elle couvrait aussi les aplats d'accent jusqu'au 2026-09-14. Ce n'est
    /// plus vrai : l'accent suit le theme, et `tileInk` dessus tombait a
    /// 1,72:1. C'est `onAccent` qui va sur l'accent.
    public static let tileInk = Token.fixed(0x2A1140)

    /// Encre posee sur un aplat d'ACCENT (`neon`, `neonDeep`, `neonSoft`, et
    /// les fonds `premium` qui en derivent). Le `--color-sur-surimpression`
    /// du web : creme sur l'accent pourpre du theme clair (9,31:1), pourpre
    /// sur l'accent jaune du theme sombre (11,42:1).
    ///
    /// C'est le SEUL jeton que l'alignement du 2026-09-14 a ajoute, et sa
    /// raison d'etre n'est pas cosmetique : tant que l'accent etait un orange,
    /// clair dans les deux themes comme les ambres, une seule encre suffisait.
    public static let onAccent = Token.dynamic(light: 0xFFF9F0, dark: 0x2A1140)

    // MARK: - Semantic states

    public static let premium = Token.dynamic(light: 0x5B2C87, dark: 0xFFD029)
    public static let success = Token.dynamic(light: 0x1B6B45, dark: 0x86DCAC)
    public static let warning = Token.dynamic(light: 0x7A5200, dark: 0xFFB020)
    /// Theme-able semantic red (errors, destructive actions, countdowns) -
    /// distinct from the fixed `cardRed` pip color even though they share
    /// the same light-theme value.
    public static let danger = Token.dynamic(light: 0x8E2A14, dark: 0xFF9C84)
}
