import Foundation

/// Raw Meskova design tokens - platform-agnostic (no SwiftUI/UIKit import),
/// so both the app's `Theme.Color` (SwiftUI, `Meskova/Theme/Theme.swift`)
/// and the CI contrast guard (`MeskovaTests/ContrastGuardTests.swift`) build
/// on the exact same source of truth. Mirrors
/// `la-taverne/src/styles/tokens.css` and `docs/DESIGN_TOKENS.md` - never
/// edit a hex value here without updating both, and never let `Theme.swift`
/// hardcode a hex literal that duplicates one of these.
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

    public static let background = Token.dynamic(light: 0xFFF9F0, dark: 0x141216)
    public static let backgroundRaised = Token.dynamic(light: 0xFFF3E0, dark: 0x221E28)
    public static let surface = Token.dynamic(light: 0xFFFFFF, dark: 0x2E2836)
    public static let surfaceElevated = Token.dynamic(light: 0xFFEFD6, dark: 0x3C3446)

    // MARK: - Ink (inverts with theme: dark in light mode, cream in dark mode)

    public static let ink = Token.dynamic(light: 0x111111, dark: 0xF4EFE6)
    public static let inkSecondary = Token.dynamic(light: 0x44444A, dark: 0xA39DB0)
    public static let inkMuted = Token.dynamic(light: 0x6B6B70, dark: 0x958FA3)

    // MARK: - Brand accent ("neon" keeps its historical token name)

    public static let neon = Token.dynamic(light: 0xFA5600, dark: 0xFF7A2E)
    public static let neonDeep = Token.dynamic(light: 0xE24E00, dark: 0xE86014)
    public static let neonSoft = Token.dynamic(light: 0xFF8A3D, dark: 0xFF9E5C)
    public static let orangeInk = Token.dynamic(light: 0xC74300, dark: 0xFF7A2E)

    // MARK: - Festive "pop" tile fills - stay light in BOTH themes

    public static let popYellow = Token.dynamic(light: 0xFFD029, dark: 0xFFD84D)
    public static let popPink = Token.dynamic(light: 0xFF6FB2, dark: 0xFF7FBE)
    public static let popBlue = Token.dynamic(light: 0x6E9BFF, dark: 0x7FB0FF)
    public static let popLime = Token.dynamic(light: 0x9BE94C, dark: 0xA6F05A)

    // MARK: - Fixed tokens: physical card / tile objects, never themed

    public static let cardFace = Token.fixed(0xFFFFFF)
    public static let cardInk = Token.fixed(0x111111)
    /// Playing-card pip red. Reserved for content posed on `cardFace`
    /// (hearts/diamonds pips, roulette/tribunal result labels) - never a
    /// semantic "error" UI color, see `danger` below.
    public static let cardRed = Token.fixed(0xC71F2D)
    /// Fixed dark ink for text/icons/borders placed directly on a pop/neon
    /// fill (both stay light in both themes) - must never follow the theme.
    /// Numerically identical to `cardInk` (same reasoning: a fixed-light
    /// backing), kept as a separate named token to match
    /// `docs/DESIGN_TOKENS.md` section 2bis and `--color-tile-ink` on web.
    // TEMPORARY REGRESSION INJECTION - proves ContrastGuardTests catches the
    // reported bug for real (see PR description). Reverted in the next commit.
    public static let tileInk = Token.dynamic(light: 0x111111, dark: 0xF4EFE6)

    // MARK: - Semantic states

    public static let premium = Token.dynamic(light: 0x855C12, dark: 0xD9A441)
    public static let success = Token.dynamic(light: 0x177C50, dark: 0x3EA876)
    public static let warning = Token.dynamic(light: 0xB45309, dark: 0xD67428)
    /// Theme-able semantic red (errors, destructive actions, countdowns) -
    /// distinct from the fixed `cardRed` pip color even though they share
    /// the same light-theme value.
    public static let danger = Token.dynamic(light: 0xC71F2D, dark: 0xFF7878)
}
