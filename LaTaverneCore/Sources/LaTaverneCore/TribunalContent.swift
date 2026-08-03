import Foundation

/// One embedded charge for "Le Pilori", used when the table skips writing
/// its own accusations. Mirrors `la-taverne/src/content/tribunal.ts`; keep
/// both in sync when the deck changes.
public struct TribunalCharge: Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

/// Le Tribunal is an embedded game mode: no content pack, no JSON source.
/// Chefs d'accusation store-safe: jamais d'alcool nommé, uniquement des
/// pénalités abstraites.
public enum TribunalContent {
    public static let tribunalCharges: [TribunalCharge] = [
        TribunalCharge(id: "tri-01", text: "Complot de silence : avoir laissé un pote se faire accuser sans lever le petit doigt."),
        TribunalCharge(id: "tri-02", text: "Usage abusif du téléphone en pleine partie, au vu et au su de la table."),
        TribunalCharge(id: "tri-03", text: "Trahison caractérisée : avoir voté contre son propre binôme au tour précédent."),
        TribunalCharge(id: "tri-04", text: "Rire suspect en pleine question sérieuse, laissant planer le doute."),
        TribunalCharge(id: "tri-05", text: "Fuite d'information : avoir soufflé une réponse à voix (trop) basse."),
        TribunalCharge(id: "tri-06", text: "Triche présumée sur un pierre-feuille-ciseaux disputé."),
        TribunalCharge(id: "tri-07", text: "Abandon de poste : s'être levé sans prévenir la cour."),
        TribunalCharge(id: "tri-08", text: "Mensonge flagrant sur son propre score de la soirée."),
        TribunalCharge(id: "tri-09", text: "Complicité de retard général en ayant proposé une pause non votée."),
        TribunalCharge(id: "tri-10", text: "Détournement d'attention : avoir changé de sujet pour éviter une pénalité.")
    ]
}
