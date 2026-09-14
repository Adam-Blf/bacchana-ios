import SwiftUI
import UIKit
import BacchanaCore

/// Bacchana design tokens: tavern neobrutalist palette. Every value below is
/// built from `BacchanaCore.ThemePalette` - the single, platform-agnostic
/// source of truth shared with the CI contrast guard
/// (`BacchanaTests/ContrastGuardTests.swift`) - which itself mirrors
/// `bacchana-site/src/styles/tokens.css` and `docs/DESIGN_TOKENS.md`. Update
/// `ThemePalette`, not a hex literal here, when the palette changes. Every
/// `Theme.Color` token built via `.dynamic` resolves to its light or dark
/// pair from the same `UIColor` trait-collection closure, so call sites
/// never need to know which theme is active - only ``ThemeMode`` (persisted
/// in `AppState`) decides which scheme SwiftUI resolves against.
enum Theme {
    enum Color {
        // Encre neutre en sombre (JAMAIS de brun/bois) : voir ThemePalette
        // et docs/DESIGN_TOKENS.md pour les ratios WCAG calculés par token.
        static let background = SwiftUI.Color.dynamic(ThemePalette.background)
        static let backgroundRaised = SwiftUI.Color.dynamic(ThemePalette.backgroundRaised)
        static let surface = SwiftUI.Color.dynamic(ThemePalette.surface)
        static let surfaceElevated = SwiftUI.Color.dynamic(ThemePalette.surfaceElevated)

        static let ink = SwiftUI.Color.dynamic(ThemePalette.ink)
        static let inkSecondary = SwiftUI.Color.dynamic(ThemePalette.inkSecondary)
        static let inkMuted = SwiftUI.Color.dynamic(ThemePalette.inkMuted)

        /// "neon" garde son nom historique de token : c'est l'accent de marque (orange).
        static let neon = SwiftUI.Color.dynamic(ThemePalette.neon)
        static let neonDeep = SwiftUI.Color.dynamic(ThemePalette.neonDeep)
        static let neonSoft = SwiftUI.Color.dynamic(ThemePalette.neonSoft)
        /// Orange utilisé comme TEXTE (labels, liens) : passe l'AA normal (4.5:1)
        /// en clair (#C74300) ; confondu avec `neon` en sombre où l'accent est
        /// déjà assez clair pour le texte (#FF7A2E, 7.16:1).
        static let orangeInk = SwiftUI.Color.dynamic(ThemePalette.orangeInk)

        /// Les quatre ambres (tuiles de modes, roulette) : FIXES dans les deux
        /// thèmes. Tout texte/icône posé dessus utilise `tileInk` (fixe), jamais
        /// `ink` (thémable) - piège corrigé le 2026-08-04, voir
        /// docs/DESIGN_TOKENS.md section 2bis.
        static let aplat1 = SwiftUI.Color(hex: ThemePalette.aplat1.light)
        static let aplat2 = SwiftUI.Color(hex: ThemePalette.aplat2.light)
        static let aplat3 = SwiftUI.Color(hex: ThemePalette.aplat3.light)
        static let aplat4 = SwiftUI.Color(hex: ThemePalette.aplat4.light)

        /// Carte blanche : élément signature fixe, identique dans les deux thèmes
        /// (métaphore de carte physique), jamais inversée en sombre.
        static let cardFace = SwiftUI.Color(hex: ThemePalette.cardFace.light)
        static let cardInk = SwiftUI.Color(hex: ThemePalette.cardInk.light)
        /// Rouge des cartes : fixe lui aussi (assombri à 0xC71F2D pour 5.73:1 sur
        /// `cardFace`, cf. ThemePalette). Réservé aux pips physiques (cœur/carreau)
        /// et au contenu posé sur `cardFace` - jamais un rouge d'UI sémantique,
        /// utiliser `danger` pour ça (erreur, action destructive, compte à rebours).
        static let cardRed = SwiftUI.Color(hex: ThemePalette.cardRed.light)
        /// Encre fixe pour tout texte/icône/bordure posé sur un des quatre
        /// AMBRES : ces fonds restent clairs dans les deux thèmes, donc leur
        /// premier plan ne doit JAMAIS suivre `ink` (qui s'inverse en sombre).
        /// Même valeur que `cardInk`, nom distinct pour matcher
        /// `--color-tile-ink` (web).
        static let tileInk = SwiftUI.Color(hex: ThemePalette.tileInk.light)

        /// Encre posée sur un aplat d'ACCENT (`neon`, `neonDeep`, `neonSoft`,
        /// `premium`). Elle valait `tileInk` jusqu'au 2026-09-14, et c'était
        /// juste tant que l'accent était un ORANGE, clair dans les deux thèmes
        /// comme les ambres. Il vaut désormais pourpre sur fond clair et jaune
        /// sur fond pourpre : `tileInk` dessus tombait à 1,72:1.
        static let onAccent = SwiftUI.Color.dynamic(ThemePalette.onAccent)

        static let premium = SwiftUI.Color.dynamic(ThemePalette.premium)
        static let success = SwiftUI.Color.dynamic(ThemePalette.success)
        static let warning = SwiftUI.Color.dynamic(ThemePalette.warning)
        /// Rouge sémantique thémable (erreur, action destructive, compte à
        /// rebours) - distinct de `cardRed` (fixe, réservé aux pips/cardFace)
        /// même si les deux partagent la même valeur en thème clair.
        static let danger = SwiftUI.Color.dynamic(ThemePalette.danger)

        /// Le filet gravé, seul repère d'élévation du système - il n'y a plus
        /// d'ombre portée. Les deux thèmes passent à 0,48, la valeur du web :
        /// 3,14:1 en clair, 3,37:1 en sombre, au-dessus du plancher 1.4.11 pour
        /// un objet non textuel. Le clair valait 0,15, soit 1,76:1, sous le
        /// plancher - et c'était documenté comme une exclusion, pas comme un
        /// choix.
        static let border = SwiftUI.Color.dynamic(
            light: ThemePalette.ink.light, lightOpacity: 0.48,
            dark: ThemePalette.ink.dark, darkOpacity: 0.48
        )
        static let borderStrong = SwiftUI.Color.dynamic(ThemePalette.ink)

        /// Rotation de teintes pour les GLYPHES des tuiles du Hub.
        ///
        /// ATTENTION, ce n'est PAS la rotation d'aplats du web, et la
        /// différence est structurelle, pas chromatique : le web remplit la
        /// tuile d'un ambre et pose le glyphe en `tileInk` par-dessus ; iOS
        /// garde une tuile `surface` et TEINTE le glyphe. Un ambre sur crème
        /// ne se voit pas - la rotation ne peut donc pas simplement pointer sur
        /// `aplat1` à `aplat4`.
        ///
        /// Elle valait `[neon, popPink, popBlue, popLime, popYellow]`, cinq
        /// teintes distinctes. Elle tourne désormais sur la famille d'accent,
        /// lisible sur `surface` dans les deux thèmes - mais c'est une mesure
        /// conservatoire : trois nuances d'une même teinte se distinguent moins
        /// que cinq couleurs. Reconcilier les deux dessins de tuile est une
        /// décision de design, pas un échange de jetons, et elle reste à
        /// prendre (voir bacchana/docs/AUDIT_NATIF.md).
        static let popPalette: [SwiftUI.Color] = [neon, neonSoft, neonDeep]

        /// Couleur d'accent pour la tuile de mode d'index `index`, en boucle
        /// sur `popPalette`.
        static func pop(_ index: Int) -> SwiftUI.Color {
            popPalette[index % popPalette.count]
        }
    }

    enum Font {
        /// Anton, uppercase display type for titles and giant counters.
        static func display(_ size: CGFloat) -> SwiftUI.Font {
            .custom("Anton-Regular", size: size, relativeTo: .largeTitle)
        }

        /// Space Grotesk, body and UI text. PostScript names carry a
        /// "Light" segment inherited from the static-instance export of the
        /// Google Fonts variable font; verified against the embedded TTFs.
        static func body(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            switch weight {
            case .bold:
                return .custom("SpaceGroteskLight-Bold", size: size, relativeTo: .body)
            case .medium, .semibold:
                return .custom("SpaceGroteskLight-Medium", size: size, relativeTo: .body)
            default:
                return .custom("SpaceGroteskLight-Regular", size: size, relativeTo: .body)
            }
        }

        /// Space Mono, tabular values, HUD, penalty counters.
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            weight == .bold
                ? .custom("SpaceMono-Bold", size: size, relativeTo: .body)
                : .custom("SpaceMono-Regular", size: size, relativeTo: .body)
        }
    }

    enum Radius {
        static let card: CGFloat = 16
        static let control: CGFloat = 12
        static let pill: CGFloat = 999
    }

    enum Motion {
        static let fast: Double = 0.15
        static let base: Double = 0.25
        static let flip: Double = 0.6
    }
}

/// User-facing theme preference, persisted in `AppState`. Mirrors the web's
/// `themeStore.ThemePreference` ('system' | 'light' | 'dark').
enum ThemeMode: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    /// Value handed to `.preferredColorScheme`; `nil` for `.system` lets
    /// SwiftUI follow the OS setting live, exactly like the web's
    /// `prefers-color-scheme` listener.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension SwiftUI.Color {
    /// Builds a `Color` from a 0xRRGGBB literal, matching the web token hex values.
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    /// Builds a `Color` that resolves to a different hex literal depending on
    /// the active `UITraitCollection.userInterfaceStyle`. Lets every
    /// `Theme.Color` token stay dynamic without touching call sites when the
    /// scheme changes (system toggle, or explicit `.preferredColorScheme`).
    static func dynamic(light lightHex: UInt32, lightOpacity: Double = 1, dark darkHex: UInt32, darkOpacity: Double = 1) -> SwiftUI.Color {
        SwiftUI.Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(SwiftUI.Color(hex: darkHex, opacity: darkOpacity))
                : UIColor(SwiftUI.Color(hex: lightHex, opacity: lightOpacity))
        })
    }

    /// Builds a dynamic `Color` straight from a `BacchanaCore.ThemePalette`
    /// token, so `Theme.Color` never hardcodes a hex value that could drift
    /// from the shared source of truth.
    static func dynamic(_ token: ThemePalette.Token) -> SwiftUI.Color {
        dynamic(light: token.light, dark: token.dark)
    }
}
