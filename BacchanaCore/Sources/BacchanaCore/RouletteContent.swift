import Foundation

/// One wedge of "La Roue du Destin". Mirrors `bacchana-site/src/content/roulette.ts`;
/// keep both in sync when the wheel changes.
public struct RouletteSegment: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let detail: String

    public init(id: String, label: String, detail: String) {
        self.id = id
        self.label = label
        self.detail = detail
    }
}

/// La Roue du Destin is an embedded game mode: no content pack, no named
/// player, no recap. 40 segments, store-safe: abstract penalties, ambiance
/// dares, mimes, votes and soft forfeits. Never a named alcohol, never a
/// dangerous instruction.
public enum RouletteContent {
    public static let segments: [RouletteSegment] = [
        RouletteSegment(id: "rou-01", label: "1 pénalité", detail: "Le sort est clément, une seule et on n'en parle plus."),
        RouletteSegment(id: "rou-02", label: "2 pénalités", detail: "La roue hausse le ton, tu en prends deux."),
        RouletteSegment(id: "rou-03", label: "3 pénalités", detail: "Trois d'un coup, la note grimpe au comptoir."),
        RouletteSegment(id: "rou-04", label: "Pénalité majeure", detail: "Le pire tirage de la roue, encaisse sans broncher."),
        RouletteSegment(id: "rou-05", label: "Distribue 2", detail: "Désigne deux convives, chacun prend une pénalité."),
        RouletteSegment(id: "rou-06", label: "Immunité", detail: "Blindé au prochain tour, plus rien ne t'atteint."),
        RouletteSegment(id: "rou-07", label: "Toute la table", detail: "Personne n'est épargné, une pénalité pour chacun."),
        RouletteSegment(id: "rou-08", label: "Rejoue", detail: "Relance la roue immédiatement, le sort n'a pas fini."),
        RouletteSegment(id: "rou-09", label: "Mime muet", detail: "Mime un métier, la tablée devine en trente secondes."),
        RouletteSegment(id: "rou-10", label: "Grand accent", detail: "Raconte ta soirée avec l'accent que la table t'impose."),
        RouletteSegment(id: "rou-11", label: "Statue", detail: "Reste figé comme une statue jusqu'à ton prochain passage."),
        RouletteSegment(id: "rou-12", label: "Vote express", detail: "La table vote : qui a le plus de culot ce soir ?"),
        RouletteSegment(id: "rou-13", label: "Duel de regards", detail: "Fixe ton voisin, le premier qui rit prend une pénalité."),
        RouletteSegment(id: "rou-14", label: "Compliment", detail: "Fais un vrai compliment à la personne à ta gauche."),
        RouletteSegment(id: "rou-15", label: "Anecdote", detail: "Balance une anecdote gênante en moins d'une minute."),
        RouletteSegment(id: "rou-16", label: "Imitation", detail: "Imite un convive, il doit deviner de qui il s'agit."),
        RouletteSegment(id: "rou-17", label: "Refrain", detail: "Chante le refrain que la table te souffle."),
        RouletteSegment(id: "rou-18", label: "Grimace", detail: "Tiens la grimace la plus laide pendant dix secondes."),
        RouletteSegment(id: "rou-19", label: "Silence d'or", detail: "Interdit de parler jusqu'à ton prochain passage."),
        RouletteSegment(id: "rou-20", label: "Slogan", detail: "Invente un slogan pour la soirée, la table juge."),
        RouletteSegment(id: "rou-21", label: "Capitaine", detail: "Tu mènes le prochain tour, tes règles font loi."),
        RouletteSegment(id: "rou-22", label: "Chaises musicales", detail: "Change de siège avec la personne assise en face."),
        RouletteSegment(id: "rou-23", label: "Main faible", detail: "Fais tout de la main gauche jusqu'au prochain tour."),
        RouletteSegment(id: "rou-24", label: "Confession", detail: "Réponds franchement à une question de la table."),
        RouletteSegment(id: "rou-25", label: "Vérité ou double", detail: "Réponds vrai ou prends deux pénalités à la place."),
        RouletteSegment(id: "rou-26", label: "Ovation", detail: "Lève-toi et salue, la table t'offre une ovation."),
        RouletteSegment(id: "rou-27", label: "Roulement", detail: "Tape la table en rythme, tout le monde doit suivre."),
        RouletteSegment(id: "rou-28", label: "Pause fraîcheur", detail: "Va chercher de l'eau pour la personne de ton choix."),
        RouletteSegment(id: "rou-29", label: "Question piège", detail: "Pose une colle à la table, le premier bloqué prend une pénalité."),
        RouletteSegment(id: "rou-30", label: "Photo souvenir", detail: "Prends la pose, la table improvise une photo de groupe."),
        RouletteSegment(id: "rou-31", label: "Deux pas", detail: "Improvise deux pas de danse au choix de la table."),
        RouletteSegment(id: "rou-32", label: "Accent voyage", detail: "Parle avec un accent étranger jusqu'au prochain tour."),
        RouletteSegment(id: "rou-33", label: "Éloge", detail: "Fais l'éloge exagéré de ton voisin de droite."),
        RouletteSegment(id: "rou-34", label: "Pénalité partagée", detail: "Toi et ton voisin prenez une pénalité ensemble."),
        RouletteSegment(id: "rou-35", label: "Renversement", detail: "La personne à ta droite prend ta pénalité à ta place."),
        RouletteSegment(id: "rou-36", label: "Défi minute", detail: "La table te lance un défi soft à réaliser sur-le-champ."),
        RouletteSegment(id: "rou-37", label: "Chef de chœur", detail: "Fais chanter la table trois secondes, à toi de lancer."),
        RouletteSegment(id: "rou-38", label: "Roue clémente", detail: "Rien ne se passe, savoure ta chance et passe la main."),
        RouletteSegment(id: "rou-39", label: "Meneur du soir", detail: "Choisis le thème du prochain tour, la table te suit."),
        RouletteSegment(id: "rou-40", label: "Double ou rien", detail: "Relance : gros lot de pénalités ou immunité, la roue tranche.")
    ]
}
