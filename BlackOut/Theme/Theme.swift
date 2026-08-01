import SwiftUI

/// Neo-Tokyo Borderland design tokens, ported 1:1 from
/// `blackout-content/tokens/tokens.json`. Source of truth lives there;
/// update both when the palette changes.
enum Theme {
    enum Color {
        static let background = SwiftUI.Color(hex: 0x09090B)
        static let backgroundRaised = SwiftUI.Color(hex: 0x0E0E12)
        static let surface = SwiftUI.Color(hex: 0x15151A)
        static let surfaceElevated = SwiftUI.Color(hex: 0x1C1C23)
        static let ink = SwiftUI.Color(hex: 0xFAFAF7)
        static let inkSecondary = SwiftUI.Color(hex: 0xA1A1AA)
        static let inkMuted = SwiftUI.Color(hex: 0x63636B)
        static let neon = SwiftUI.Color(hex: 0xFF3B41)
        static let neonDeep = SwiftUI.Color(hex: 0xDC2626)
        static let neonSoft = SwiftUI.Color(hex: 0xFF6B6E)
        static let cardFace = SwiftUI.Color(hex: 0xF7F5F0)
        static let cardInk = SwiftUI.Color(hex: 0x111114)
        static let cardRed = SwiftUI.Color(hex: 0xE5323E)
        static let premium = SwiftUI.Color(hex: 0xD4A437)
        static let success = SwiftUI.Color(hex: 0x10B981)
        static let warning = SwiftUI.Color(hex: 0xF59E0B)
        static let border = SwiftUI.Color(hex: 0xFAFAF7).opacity(0.08)
        static let borderStrong = SwiftUI.Color(hex: 0xFAFAF7).opacity(0.16)
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

extension SwiftUI.Color {
    /// Builds a `Color` from a 0xRRGGBB literal, matching the web token hex values.
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
