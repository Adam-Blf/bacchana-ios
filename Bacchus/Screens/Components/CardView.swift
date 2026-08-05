import SwiftUI
import BacchusCore

/// The signature giant playing card, face shown centered on the paper table.
struct CardView: View {
    let card: Card?
    var isFlipped: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(isFlipped ? Theme.Color.cardFace : Theme.Color.surfaceElevated)

            if isFlipped, let card {
                VStack(spacing: 12) {
                    Text(card.rank.rawValue)
                        .font(Theme.Font.display(56))
                        .foregroundStyle(suitColor(card.suit))
                    Image(systemName: symbolName(card.suit))
                        .font(.system(size: 40))
                        .foregroundStyle(suitColor(card.suit))
                }
            } else {
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Color.neon.opacity(0.3))
            }
        }
        .frame(width: 220, height: 320)
        // Hard black offset shadow, no glow (neobrutalist token shadow.brutal-lg).
        .shadow(color: Theme.Color.ink, radius: 0, x: 7, y: 7)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.ink, lineWidth: 2)
        )
        .accessibilityLabel(card.map(accessibilityDescription) ?? "Carte face cachée")
    }

    private func suitColor(_ suit: Suit) -> Color {
        switch suit {
        case .hearts, .diamonds: return Theme.Color.cardRed
        case .clubs, .spades: return Theme.Color.cardInk
        }
    }

    private func symbolName(_ suit: Suit) -> String {
        switch suit {
        case .clubs: return "suit.club.fill"
        case .diamonds: return "suit.diamond.fill"
        case .hearts: return "suit.heart.fill"
        case .spades: return "suit.spade.fill"
        }
    }

    private func accessibilityDescription(_ card: Card) -> String {
        let suitName: String
        switch card.suit {
        case .clubs: suitName = "trèfle"
        case .diamonds: suitName = "carreau"
        case .hearts: suitName = "coeur"
        case .spades: suitName = "pique"
        }
        return "\(card.rank.rawValue) de \(suitName)"
    }
}
