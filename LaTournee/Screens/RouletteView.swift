import SwiftUI
import UIKit
import LaTourneeCore

/// La Roulette - "La Roue du Destin". Embedded game mode: no content pack,
/// no named player, no recap. 40-segment wheel, casino-style spin animation,
/// then a fixed result card. Mirrors
/// `la-taverne/src/components/screens/RouletteScreen.tsx`.
struct RouletteView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let segments = RouletteContent.segments
    private let wheelColors: [Color] = [Theme.Color.neon, Theme.Color.popYellow]
    private var segmentAngle: Double { 360.0 / Double(segments.count) }

    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var pendingIndex: Int?
    @State private var resultIndex: Int?
    // La roue ne désigne pas nommément le joueur puni, donc pas d'addition
    // chiffrée par joueur : on compte les tours pour clôturer la session.
    @State private var spinsPlayed = 0

    var body: some View {
        VStack(spacing: 24) {
            header

            Spacer()

            wheel

            if let result {
                resultCard(result)
            }

            Spacer()

            spinButton
        }
        .padding(20)
    }

    private var result: RouletteSegment? {
        guard let resultIndex else { return nil }
        return segments[resultIndex]
    }

    private var header: some View {
        HStack {
            Button(action: handleQuit) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.Color.ink)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Quitter la roulette et revenir à l'accueil")

            Spacer()

            Text("LA ROUE DU DESTIN")
                .font(Theme.Font.body(13, weight: .medium))
                .foregroundStyle(Theme.Color.inkSecondary)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var wheel: some View {
        ZStack {
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    WheelSlice(index: index, total: segments.count)
                        .fill(wheelColors[index % wheelColors.count])

                    // tileInk, pas ink : cette bordure separe deux aplats pop/neon
                    // (toujours clairs), l'encre thematisee y deviendrait quasi
                    // invisible en sombre (contrairement a l'anneau exterieur
                    // ci-dessous, qui cadre contre le canvas et reste en ink).
                    WheelSlice(index: index, total: segments.count)
                        .stroke(Theme.Color.tileInk, lineWidth: 3)

                    segmentLabel(segment, index: index)
                }
            }
            .frame(width: 280, height: 280)
            .clipShape(Circle())
            .overlay(Circle().stroke(Theme.Color.ink, lineWidth: 4))
            .rotationEffect(.degrees(rotation))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Roue de la fortune, \(segments.count) segments")

            pointer

            centerHub
        }
        .frame(width: 300, height: 300)
        .shadow(color: Theme.Color.ink.opacity(0.2), radius: 0, x: 6, y: 6)
    }

    private func segmentLabel(_ segment: RouletteSegment, index: Int) -> some View {
        let midAngle = Double(index) * segmentAngle + segmentAngle / 2
        let angleRadians = (midAngle - 90) * .pi / 180
        let labelRadius: CGFloat = 95

        return Text(segment.label)
            .font(Theme.Font.mono(9, weight: .bold))
            // tileInk : ce libelle est pose sur un aplat pop/neon plein, cf. wheel.
            .foregroundStyle(Theme.Color.tileInk)
            .multilineTextAlignment(.center)
            .frame(width: 72)
            .lineLimit(2)
            .rotationEffect(.degrees(midAngle))
            .offset(x: labelRadius * cos(angleRadians), y: labelRadius * sin(angleRadians))
    }

    private var pointer: some View {
        Triangle()
            .fill(Theme.Color.ink)
            .frame(width: 22, height: 16)
            .offset(y: -156)
            .accessibilityHidden(true)
    }

    private var centerHub: some View {
        Circle()
            .fill(Theme.Color.surface)
            .frame(width: 56, height: 56)
            .overlay(Circle().stroke(Theme.Color.ink, lineWidth: 2))
            .overlay(
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.Color.neon)
            )
            .accessibilityHidden(true)
    }

    private func resultCard(_ segment: RouletteSegment) -> some View {
        VStack(spacing: 8) {
            Text(segment.label)
                .font(Theme.Font.display(22))
                .foregroundStyle(Theme.Color.cardRed)
                .multilineTextAlignment(.center)
            Text(segment.detail)
                .font(Theme.Font.body(14))
                // cardInk (fixe) attenue, pas inkSecondary (thematisee) : ce texte
                // est pose directement sur cardFace, fixe blanc dans les 2 themes.
                .foregroundStyle(Theme.Color.cardInk.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.Color.cardFace)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
    }

    private var spinButton: some View {
        Button(action: handleSpin) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text(spinning ? "Ça tourne…" : "Lancer la roue")
                    .font(Theme.Font.body(16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        // tileInk : fond neonDeep plein, clair dans les 2 themes.
        .foregroundStyle(Theme.Color.tileInk)
        .background(Theme.Color.neonDeep)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
        .opacity(spinning ? 0.7 : 1)
        .disabled(spinning)
    }

    private func handleSpin() {
        guard !spinning else { return }
        haptic(.medium)

        let index = Int.random(in: 0..<segments.count)
        let targetCenter = Double(index) * segmentAngle + segmentAngle / 2
        let base = ((rotation + 1) / 360).rounded(.up) * 360
        let nextRotation = base + 5 * 360 + (360 - targetCenter)

        pendingIndex = index
        resultIndex = nil
        spinning = true

        guard !reduceMotion else {
            rotation = nextRotation
            finishSpin()
            return
        }

        withAnimation(
            .timingCurve(0.17, 0.67, 0.12, 0.99, duration: 3.2),
            completionCriteria: .logicallyComplete
        ) {
            rotation = nextRotation
        } completion: {
            finishSpin()
        }
    }

    private func finishSpin() {
        spinning = false
        resultIndex = pendingIndex
        if pendingIndex != nil {
            haptic(.heavy)
            spinsPlayed += 1
        }
    }

    private func handleQuit() {
        appState.analytics.track(
            "session_completed",
            properties: ["mode": "roulette", "turns": String(spinsPlayed)]
        )
        appState.route = .hub
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// One pie wedge of the wheel, `index` out of `total`, starting at the top
/// (12 o'clock) and sweeping clockwise, matching the web `conic-gradient`.
private struct WheelSlice: Shape {
    let index: Int
    let total: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let segmentAngle = 360.0 / Double(total)
        let start = Angle(degrees: -90 + Double(index) * segmentAngle)
        let end = Angle(degrees: -90 + Double(index + 1) * segmentAngle)

        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        path.closeSubpath()
        return path
    }
}

/// Fixed pointer at the top of the wheel, apex down.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
