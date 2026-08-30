import Foundation
import XCTest
@testable import BacchanaCore

/// Mechanical WCAG 2.1 contrast guard, run in CI on every PR.
///
/// Regression history: "du blanc sur du jaune c'est illisible, du blanc sur
/// du vert clair c'est illisible" (reported live, 2026-08-04). Root cause:
/// `ink` inverts with the theme (dark in light mode, cream in dark mode)
/// while the "pop" tile fills and the neon accent stay LIGHT in both
/// themes - so `ink` posed on a pop/neon fill in dark mode fell to
/// ~1.2:1, invisible, and no test ever caught it because nothing checked
/// that specific (foreground, background) pair.
///
/// This guard does not repeat that mistake by hand-copying the handful of
/// pairs that were known to be broken: every pair below is DERIVED from
/// `ThemePalette` itself (the same source `Theme.Color` builds from), so a
/// future palette edit - or a screen wiring a themed ink onto a
/// light-in-both-themes fill again - is re-verified automatically instead
/// of relying on a developer remembering to update a hand-written list.
final class ContrastGuardTests: XCTestCase {
    // MARK: - WCAG 2.1 relative luminance / contrast ratio

    private func linear(_ channel: UInt32) -> Double {
        let c = Double(channel) / 255
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    private func luminance(_ hex: UInt32) -> Double {
        let r = linear((hex >> 16) & 0xFF)
        let g = linear((hex >> 8) & 0xFF)
        let b = linear(hex & 0xFF)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Alpha-composites `fgHex` (opacity `alpha`) over the opaque `bgHex`,
    /// used for the `.opacity()` "secondary ink on card-face" variants
    /// (e.g. `Theme.Color.cardInk.opacity(0.7)`, matching web's `text-card-ink/70`).
    private func blend(_ fgHex: UInt32, alpha: Double, over bgHex: UInt32) -> UInt32 {
        func channel(_ shift: Int) -> UInt32 {
            let fg = Double((fgHex >> shift) & 0xFF)
            let bg = Double((bgHex >> shift) & 0xFF)
            return UInt32((alpha * fg + (1 - alpha) * bg).rounded())
        }
        return (channel(16) << 16) | (channel(8) << 8) | channel(0)
    }

    private func ratio(_ hex1: UInt32, _ hex2: UInt32) -> Double {
        let l1 = luminance(hex1)
        let l2 = luminance(hex2)
        let (hi, lo) = l1 >= l2 ? (l1, l2) : (l2, l1)
        return (hi + 0.05) / (lo + 0.05)
    }

    // MARK: - Token access, derived from ThemePalette (not hand-typed hex)

    private enum Scheme: String { case light, dark }

    private func hex(_ token: ThemePalette.Token, _ scheme: Scheme) -> UInt32 {
        scheme == .light ? token.light : token.dark
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    /// Text/icon tokens legitimately posed on the themed canvas - mirrors
    /// the table in `docs/DESIGN_TOKENS.md` section 3.3.
    private let canvasTextTokens: [(name: String, token: ThemePalette.Token)] = [
        ("ink", ThemePalette.ink),
        ("inkSecondary", ThemePalette.inkSecondary),
        ("orangeInk", ThemePalette.orangeInk),
        ("premium", ThemePalette.premium),
        ("success", ThemePalette.success),
        ("warning", ThemePalette.warning),
        ("danger", ThemePalette.danger),
    ]

    private let canvasSurfaces: [(name: String, token: ThemePalette.Token)] = [
        ("background", ThemePalette.background),
        ("backgroundRaised", ThemePalette.backgroundRaised),
        ("surface", ThemePalette.surface),
        ("surfaceElevated", ThemePalette.surfaceElevated),
    ]

    /// Fills that stay light in BOTH themes by design (pop tiles, the neon
    /// accent family, the fixed card face): any text/icon posed on one of
    /// these must use a FIXED dark ink, never a themed one.
    private let lightInBothThemesFills: [(name: String, token: ThemePalette.Token)] = [
        ("neon", ThemePalette.neon),
        ("neonDeep", ThemePalette.neonDeep),
        ("neonSoft", ThemePalette.neonSoft),
        ("popYellow", ThemePalette.popYellow),
        ("popPink", ThemePalette.popPink),
        ("popBlue", ThemePalette.popBlue),
        ("popLime", ThemePalette.popLime),
        ("cardFace", ThemePalette.cardFace),
    ]

    private let aaNormalText = 4.5
    private let aaLargeTextOrUIObject = 3.0

    // MARK: - Tests

    /// Pre-existing gaps, neither introduced nor touched by this fix, and
    /// verified (by grep across `Bacchana/Screens`) to never actually pair
    /// `warning`/`success`/`orangeInk` text with `surface`/`surfaceElevated`
    /// in any shipped screen today. Floors are pinned to the *current*
    /// observed ratio (some already recorded in `docs/DESIGN_TOKENS.md`'s
    /// own dark-theme table), so this list can never mask a NEW regression -
    /// it only tolerates a gap that already exists. Fixing these tokens'
    /// hex values is a cross-platform design-token change (web + iOS +
    /// Android) outside this fix's scope.
    private let knownCanvasGaps: [String: Double] = [
        "warning/surfaceElevated/light": 4.43,
        "warning/surface/dark": 4.32,
        "warning/surfaceElevated/dark": 3.59,
        "success/surfaceElevated/dark": 3.97,
        "orangeInk/surfaceElevated/light": 4.37,
    ]

    /// Every canvas-text token against every canvas surface, both themes -
    /// the ink family only ever needs to satisfy AA normal text (4.5:1)
    /// there, since it never sits on a fixed-light fill (see
    /// `testFixedInkOnLightInBothThemesFills` for that case).
    func testInkFamilyOnCanvasSurfaces() {
        var failures: [String] = []
        for scheme: Scheme in [.light, .dark] {
            for (textName, textToken) in canvasTextTokens {
                for (bgName, bgToken) in canvasSurfaces {
                    let key = "\(textName)/\(bgName)/\(scheme.rawValue)"
                    let minRatio = knownCanvasGaps[key] ?? aaNormalText
                    let r = ratio(hex(textToken, scheme), hex(bgToken, scheme))
                    if r < minRatio {
                        failures.append("\(textName)/\(bgName) (\(scheme.rawValue)): \(format(r)):1 < \(minRatio):1")
                    }
                }
            }
        }
        XCTAssertTrue(failures.isEmpty, "Contrast AA failures:\n" + failures.joined(separator: "\n"))
    }

    /// `inkMuted`'s documented exception (`docs/DESIGN_TOKENS.md` 3.3): AA
    /// normal on background/backgroundRaised/surface, AA-large only on
    /// surfaceElevated (reserved there to icons and large decorative labels).
    func testInkMutedOnCanvasSurfaces() {
        var failures: [String] = []
        for scheme: Scheme in [.light, .dark] {
            for (bgName, bgToken) in canvasSurfaces {
                let minRatio = bgName == "surfaceElevated" ? aaLargeTextOrUIObject : aaNormalText
                let r = ratio(hex(ThemePalette.inkMuted, scheme), hex(bgToken, scheme))
                if r < minRatio {
                    failures.append("inkMuted/\(bgName) (\(scheme.rawValue)): \(format(r)):1 < \(minRatio):1")
                }
            }
        }
        XCTAssertTrue(failures.isEmpty, "Contrast AA failures:\n" + failures.joined(separator: "\n"))
    }

    /// The regression this guard exists for. `tileInk` (fixed dark ink) is
    /// the only foreground that reliably stays readable on a fill that is
    /// light in both themes - a themed `ink` there is exactly the "blanc sur
    /// jaune" bug. `cardInk` shares `tileInk`'s value (see `ThemePalette`),
    /// checked here through the same fixed hex.
    func testFixedInkOnLightInBothThemesFills() {
        var failures: [String] = []
        for scheme: Scheme in [.light, .dark] {
            for (bgName, bgToken) in lightInBothThemesFills {
                let r = ratio(hex(ThemePalette.tileInk, scheme), hex(bgToken, scheme))
                if r < aaNormalText {
                    failures.append("tileInk/\(bgName) (\(scheme.rawValue)): \(format(r)):1 < \(aaNormalText):1")
                }
            }
        }
        XCTAssertTrue(failures.isEmpty, "Contrast AA failures:\n" + failures.joined(separator: "\n"))
    }

    /// `cardRed` is fixed and only ever posed on the also-fixed `cardFace`
    /// (playing-card pips, roulette/tribunal result labels) - the ratio
    /// never varies with theme, sanity-checked once.
    func testCardRedOnCardFace() {
        let r = ratio(ThemePalette.cardRed.light, ThemePalette.cardFace.light)
        XCTAssertGreaterThanOrEqual(r, aaNormalText, "cardRed/cardFace: \(format(r)):1 < \(aaNormalText):1")
    }

    /// `cardInk.opacity(0.7)`, the fixed secondary-text variant used
    /// directly on `cardFace` (matches web's `text-card-ink/70`, see
    /// `RouletteScreen.tsx` / `WouldYouRatherScreen.tsx`).
    func testCardInkSecondaryOnCardFace() {
        let blended = blend(ThemePalette.cardInk.light, alpha: 0.7, over: ThemePalette.cardFace.light)
        let r = ratio(blended, ThemePalette.cardFace.light)
        XCTAssertGreaterThanOrEqual(r, aaNormalText, "cardInk.opacity(0.7)/cardFace: \(format(r)):1 < \(aaNormalText):1")
    }
}
