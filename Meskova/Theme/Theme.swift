import SwiftUI
import UIKit

/// Meskova design tokens: tavern neobrutalist palette, mirrors
/// `la-taverne/src/styles/tokens.css` (source of truth for both themes).
/// Update both when the palette changes. Every `Theme.Color` token is
/// dynamic: it resolves to its light or dark pair from the same
/// `UIColor` trait-collection closure, so call sites never need to know
/// which theme is active - only ``ThemeMode`` (persisted in `AppState`)
/// decides which scheme SwiftUI resolves against.
enum Theme {
    enum Color {
        // Encre neutre en sombre (JAMAIS de brun/bois) : voir tokens.css pour
        // les ratios WCAG calculés par token.
        static let background = SwiftUI.Color.dynamic(light: 0xFFF9F0, dark: 0x141216)
        static let backgroundRaised = SwiftUI.Color.dynamic(light: 0xFFF3E0, dark: 0x1D1B20)
        static let surface = SwiftUI.Color.dynamic(light: 0xFFFFFF, dark: 0x1D1B20)
        static let surfaceElevated = SwiftUI.Color.dynamic(light: 0xFFEFD6, dark: 0x26232B)

        static let ink = SwiftUI.Color.dynamic(light: 0x111111, dark: 0xF4EFE6)
        static let inkSecondary = SwiftUI.Color.dynamic(light: 0x44444A, dark: 0xA39DB0)
        static let inkMuted = SwiftUI.Color.dynamic(light: 0x6B6B70, dark: 0x837D8F)

        /// "neon" garde son nom historique de token : c'est l'accent de marque (orange).
        static let neon = SwiftUI.Color.dynamic(light: 0xFA5600, dark: 0xFF7A2E)
        static let neonDeep = SwiftUI.Color.dynamic(light: 0xE24E00, dark: 0xE86014)
        static let neonSoft = SwiftUI.Color.dynamic(light: 0xFF8A3D, dark: 0xFF9E5C)
        /// Orange utilisé comme TEXTE (labels, liens) : passe l'AA normal (4.5:1)
        /// en clair (#C74300) ; confondu avec `neon` en sombre où l'accent est
        /// déjà assez clair pour le texte (#FF7A2E, 7.16:1).
        static let orangeInk = SwiftUI.Color.dynamic(light: 0xC74300, dark: 0xFF7A2E)

        /// Aplats festifs "pop" (tuiles de modes, roulette).
        static let popYellow = SwiftUI.Color.dynamic(light: 0xFFD029, dark: 0xFFD84D)
        static let popPink = SwiftUI.Color.dynamic(light: 0xFF6FB2, dark: 0xFF7FBE)
        static let popBlue = SwiftUI.Color.dynamic(light: 0x6E9BFF, dark: 0x7FB0FF)
        static let popLime = SwiftUI.Color.dynamic(light: 0x9BE94C, dark: 0xA6F05A)

        /// Carte blanche : élément signature fixe, identique dans les deux thèmes
        /// (métaphore de carte physique), jamais inversée en sombre.
        static let cardFace = SwiftUI.Color(hex: 0xFFFFFF)
        static let cardInk = SwiftUI.Color(hex: 0x111111)
        /// Rouge des cartes : fixe lui aussi (assombri à 0xC71F2D pour 5.73:1 sur
        /// `cardFace`, cf. tokens.css).
        static let cardRed = SwiftUI.Color(hex: 0xC71F2D)

        static let premium = SwiftUI.Color.dynamic(light: 0x855C12, dark: 0xD9A441)
        static let success = SwiftUI.Color.dynamic(light: 0x177C50, dark: 0x3EA876)
        static let warning = SwiftUI.Color.dynamic(light: 0xB45309, dark: 0xD67428)

        static let border = SwiftUI.Color.dynamic(light: 0x111111, lightOpacity: 0.15, dark: 0xF4EFE6, darkOpacity: 0.2)
        static let borderStrong = SwiftUI.Color.dynamic(light: 0x111111, dark: 0xF4EFE6)

        /// Rotation des aplats "pop" pour les icônes des tuiles du Hub -
        /// signature visuelle festive plutôt qu'un accent unique répété sur
        /// chaque mode. `neon` reste l'accent principal (Le Coupe-Gorge, jeu
        /// signature), les autres suivent.
        static let popPalette: [SwiftUI.Color] = [neon, popPink, popBlue, popLime, popYellow]

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
}
