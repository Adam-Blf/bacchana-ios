import Foundation

/// One secret ranking question for "Le Tableau d'Honneur". Mirrors
/// `bacchana-site/src/content/ranking.ts`; keep both in sync when the deck changes.
public struct RankingQuestion: Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

/// Le Tableau d'Honneur is an embedded game mode: no content pack, no JSON
/// source. Questions de classement 100 % originales. Store-safe : jamais
/// d'alcool nommé.
public enum RankingContent {
    public static let rankingQuestions: [RankingQuestion] = [
        RankingQuestion(id: "rk-01", text: "Du plus susceptible de devenir célèbre au moins susceptible"),
        RankingQuestion(id: "rk-02", text: "Du plus gros dormeur au plus matinal"),
        RankingQuestion(id: "rk-03", text: "Du plus dramatique au plus zen"),
        RankingQuestion(id: "rk-04", text: "Du plus radin au plus dépensier"),
        RankingQuestion(id: "rk-05", text: "Du plus accro à son téléphone au plus détaché"),
        RankingQuestion(id: "rk-06", text: "Du plus susceptible de survivre à une apocalypse zombie au premier éliminé"),
        RankingQuestion(id: "rk-07", text: "Du meilleur danseur au plus grand danger public en soirée"),
        RankingQuestion(id: "rk-08", text: "Du plus mauvais perdant au plus fair-play"),
        RankingQuestion(id: "rk-09", text: "Du plus susceptible d'arriver en retard à son propre mariage au plus ponctuel"),
        RankingQuestion(id: "rk-10", text: "Du plus grand cœur d'artichaut au plus difficile à séduire"),
        RankingQuestion(id: "rk-11", text: "Du plus têtu au plus influençable"),
        RankingQuestion(id: "rk-12", text: "Du plus susceptible de finir président au plus anarchiste"),
        RankingQuestion(id: "rk-13", text: "Du plus gourmand au plus difficile à table"),
        RankingQuestion(id: "rk-14", text: "Du plus maladroit au plus adroit de ses mains"),
        RankingQuestion(id: "rk-15", text: "Du plus bavard au plus mystérieux"),
        RankingQuestion(id: "rk-16", text: "Du plus susceptible de pleurer devant un film au plus insensible"),
        RankingQuestion(id: "rk-17", text: "Du plus aventurier au plus casanier"),
        RankingQuestion(id: "rk-18", text: "Du plus fort en mytho au plus transparent"),
        RankingQuestion(id: "rk-19", text: "Du plus stylé au plus « confort avant tout »"),
        RankingQuestion(id: "rk-20", text: "Du plus susceptible d'oublier un anniversaire au plus attentionné"),
        RankingQuestion(id: "rk-21", text: "Du plus compétitif au plus « c'est juste un jeu »"),
        RankingQuestion(id: "rk-22", text: "Du plus susceptible de se perdre avec un GPS au meilleur sens de l'orientation"),
        RankingQuestion(id: "rk-23", text: "Du plus fêtard au premier à rentrer"),
        RankingQuestion(id: "rk-24", text: "Du plus susceptible d'adopter cinq chats au plus allergique aux animaux"),
        RankingQuestion(id: "rk-25", text: "Du plus beau parleur au plus timide"),
        RankingQuestion(id: "rk-26", text: "Du plus susceptible de devenir millionnaire au plus fâché avec l'argent"),
        RankingQuestion(id: "rk-27", text: "Du plus grand chef cuisinier au roi des pâtes trop cuites"),
        RankingQuestion(id: "rk-28", text: "Du plus susceptible de faire le tour du monde au plus attaché à sa ville"),
        RankingQuestion(id: "rk-29", text: "Du plus grand enfant au plus vieux dans sa tête"),
        RankingQuestion(id: "rk-30", text: "Du plus susceptible de chanter en public au plus discret sous la douche"),
        RankingQuestion(id: "rk-31", text: "Du plus optimiste au plus pessimiste"),
        RankingQuestion(id: "rk-32", text: "Du plus susceptible de répondre « oui » à tout au roi du « non »"),
        RankingQuestion(id: "rk-33", text: "Du plus sportif au plus canapé"),
        RankingQuestion(id: "rk-34", text: "Du plus susceptible d'écrire un livre au plus fâché avec les mots"),
        RankingQuestion(id: "rk-35", text: "Du plus curieux au plus « chacun sa vie »"),
        RankingQuestion(id: "rk-36", text: "Du plus susceptible de gagner un jeu télévisé au plus distrait"),
        RankingQuestion(id: "rk-37", text: "Du plus romantique au plus pragmatique"),
        RankingQuestion(id: "rk-38", text: "Du plus susceptible de parler aux inconnus au plus réservé"),
        RankingQuestion(id: "rk-39", text: "Du plus grand procrastinateur au plus organisé"),
        RankingQuestion(id: "rk-40", text: "Du plus susceptible de tout quitter pour élever des chèvres au plus urbain"),
    ]
}
