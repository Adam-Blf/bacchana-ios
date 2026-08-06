import Foundation

/// Category label for a quiz question. Mirrors the string union in
/// `bacchana-site/src/content/quiz.ts`; keep both in sync when categories change.
public enum QuizCategory: String, Equatable, Sendable, CaseIterable {
    case cultureGenerale
    case sport
    case musique
    case cineSeries
    case aTable
    case histoireGeo

    public var label: String {
        switch self {
        case .cultureGenerale: return "Culture G"
        case .sport: return "Sport"
        case .musique: return "Musique"
        case .cineSeries: return "Ciné & séries"
        case .aTable: return "À table"
        case .histoireGeo: return "Histoire-géo"
        }
    }
}

/// One question for "Quitte ou Trinque". Mirrors `bacchana-site/src/content/quiz.ts`;
/// keep both in sync when the deck changes.
public struct QuizQuestion: Identifiable, Equatable, Sendable {
    public let id: String
    public let category: QuizCategory
    public let question: String
    public let answer: String

    public init(id: String, category: QuizCategory, question: String, answer: String) {
        self.id = id
        self.category = category
        self.question = question
        self.answer = answer
    }
}

/// Quitte ou Trinque is an embedded game mode: no content pack, no JSON
/// source. Questions de culture générale 100 % originales, vérification
/// orale par la table. Store-safe : jamais d'alcool nommé, uniquement des
/// « pénalités ».
public enum QuizContent {
    public static let quizQuestions: [QuizQuestion] = [
        // Histoire-géo
        QuizQuestion(id: "qz-001", category: .histoireGeo, question: "Quelle est la capitale de l'Australie ?", answer: "Canberra (et non Sydney)"),
        QuizQuestion(id: "qz-002", category: .histoireGeo, question: "En quelle année est tombé le mur de Berlin ?", answer: "1989"),
        QuizQuestion(id: "qz-003", category: .histoireGeo, question: "Quel est le plus long fleuve de France ?", answer: "La Loire"),
        QuizQuestion(id: "qz-004", category: .histoireGeo, question: "Combien y a-t-il de pays frontaliers de la France métropolitaine ?", answer: "8 (Belgique, Luxembourg, Allemagne, Suisse, Italie, Monaco, Espagne, Andorre)"),
        QuizQuestion(id: "qz-005", category: .histoireGeo, question: "Quel océan borde la Californie ?", answer: "L'océan Pacifique"),
        QuizQuestion(id: "qz-006", category: .histoireGeo, question: "Qui était le premier président de la Ve République française ?", answer: "Charles de Gaulle"),
        QuizQuestion(id: "qz-007", category: .histoireGeo, question: "Quelle est la plus haute montagne d'Afrique ?", answer: "Le Kilimandjaro"),
        QuizQuestion(id: "qz-008", category: .histoireGeo, question: "Dans quel pays se trouve le Machu Picchu ?", answer: "Au Pérou"),
        QuizQuestion(id: "qz-009", category: .histoireGeo, question: "Quelle mer sépare l'Europe de l'Afrique ?", answer: "La mer Méditerranée"),
        QuizQuestion(id: "qz-010", category: .histoireGeo, question: "En quelle année a eu lieu le premier pas sur la Lune ?", answer: "1969"),

        // Culture G
        QuizQuestion(id: "qz-011", category: .cultureGenerale, question: "Combien de côtés possède un hexagone ?", answer: "6"),
        QuizQuestion(id: "qz-012", category: .cultureGenerale, question: "Quel est le symbole chimique de l'or ?", answer: "Au"),
        QuizQuestion(id: "qz-013", category: .cultureGenerale, question: "Combien de dents possède un adulte (dents de sagesse comprises) ?", answer: "32"),
        QuizQuestion(id: "qz-014", category: .cultureGenerale, question: "Quelle planète est la plus proche du Soleil ?", answer: "Mercure"),
        QuizQuestion(id: "qz-015", category: .cultureGenerale, question: "Qui a peint « La Nuit étoilée » ?", answer: "Vincent van Gogh"),
        QuizQuestion(id: "qz-016", category: .cultureGenerale, question: "Combien de temps met la Terre pour faire le tour du Soleil ?", answer: "Environ 365 jours (un an)"),
        QuizQuestion(id: "qz-017", category: .cultureGenerale, question: "Quel animal est le plus rapide du monde en pointe ?", answer: "Le faucon pèlerin (en piqué) - accepté : le guépard sur terre"),
        QuizQuestion(id: "qz-018", category: .cultureGenerale, question: "Combien y a-t-il de lettres dans l'alphabet français ?", answer: "26"),
        QuizQuestion(id: "qz-019", category: .cultureGenerale, question: "Quel écrivain a créé le personnage d'Arsène Lupin ?", answer: "Maurice Leblanc"),
        QuizQuestion(id: "qz-020", category: .cultureGenerale, question: "De quelle couleur est le sang d'une pieuvre ?", answer: "Bleu"),

        // Sport
        QuizQuestion(id: "qz-021", category: .sport, question: "Combien de joueurs composent une équipe de football sur le terrain ?", answer: "11"),
        QuizQuestion(id: "qz-022", category: .sport, question: "Tous les combien d'années ont lieu les Jeux olympiques d'été ?", answer: "Tous les 4 ans"),
        QuizQuestion(id: "qz-023", category: .sport, question: "Dans quel sport parle-t-on de « grand chelem » ?", answer: "Le tennis (accepté : rugby, baseball)"),
        QuizQuestion(id: "qz-024", category: .sport, question: "Combien de points vaut un essai au rugby ?", answer: "5 points"),
        QuizQuestion(id: "qz-025", category: .sport, question: "Quelle est la distance officielle d'un marathon ?", answer: "42,195 km"),
        QuizQuestion(id: "qz-026", category: .sport, question: "Quel pays a remporté la Coupe du monde de football 2018 ?", answer: "La France"),
        QuizQuestion(id: "qz-027", category: .sport, question: "Dans quel sport s'illustre Teddy Riner ?", answer: "Le judo"),
        QuizQuestion(id: "qz-028", category: .sport, question: "Combien de sets faut-il gagner pour remporter un match de tennis en Grand Chelem chez les hommes ?", answer: "3 sets"),
        QuizQuestion(id: "qz-029", category: .sport, question: "Quelle course cycliste se termine traditionnellement sur les Champs-Élysées ?", answer: "Le Tour de France"),
        QuizQuestion(id: "qz-030", category: .sport, question: "Au basket, combien de points vaut un panier marqué derrière la ligne ?", answer: "3 points"),

        // Musique
        QuizQuestion(id: "qz-031", category: .musique, question: "Combien de cordes possède une guitare classique ?", answer: "6"),
        QuizQuestion(id: "qz-032", category: .musique, question: "Quel groupe anglais a chanté « Bohemian Rhapsody » ?", answer: "Queen"),
        QuizQuestion(id: "qz-033", category: .musique, question: "Quel chanteur belge a popularisé « Ne me quitte pas » ?", answer: "Jacques Brel"),
        QuizQuestion(id: "qz-034", category: .musique, question: "Combien de touches possède un piano standard ?", answer: "88"),
        QuizQuestion(id: "qz-035", category: .musique, question: "Quelle chanteuse française est surnommée « la Môme » ?", answer: "Édith Piaf"),
        QuizQuestion(id: "qz-036", category: .musique, question: "Quel instrument joue principalement un batteur ?", answer: "La batterie"),
        QuizQuestion(id: "qz-037", category: .musique, question: "De quel pays vient le groupe ABBA ?", answer: "La Suède"),
        QuizQuestion(id: "qz-038", category: .musique, question: "Quel rappeur français a sorti l'album « Deux frères » ?", answer: "PNL"),
        QuizQuestion(id: "qz-039", category: .musique, question: "Combien y a-t-il de notes dans une gamme majeure classique (sans l'octave) ?", answer: "7"),
        QuizQuestion(id: "qz-040", category: .musique, question: "Quel roi de la pop a inventé le moonwalk (ou l'a rendu célèbre) ?", answer: "Michael Jackson"),

        // Ciné & séries
        QuizQuestion(id: "qz-041", category: .cineSeries, question: "Quel réalisateur a signé « Pulp Fiction » ?", answer: "Quentin Tarantino"),
        QuizQuestion(id: "qz-042", category: .cineSeries, question: "Comment s'appelle l'école de sorciers dans Harry Potter ?", answer: "Poudlard"),
        QuizQuestion(id: "qz-043", category: .cineSeries, question: "Quel acteur incarne Jack dans « Titanic » ?", answer: "Leonardo DiCaprio"),
        QuizQuestion(id: "qz-044", category: .cineSeries, question: "Dans quelle ville se déroule la série « Friends » ?", answer: "New York"),
        QuizQuestion(id: "qz-045", category: .cineSeries, question: "Quel est le prénom du héros de « Retour vers le futur » ?", answer: "Marty (McFly)"),
        QuizQuestion(id: "qz-046", category: .cineSeries, question: "Quel studio d'animation a créé « Toy Story » ?", answer: "Pixar"),
        QuizQuestion(id: "qz-047", category: .cineSeries, question: "Comment s'appelle le vaisseau de Han Solo dans Star Wars ?", answer: "Le Faucon Millenium"),
        QuizQuestion(id: "qz-048", category: .cineSeries, question: "Quelle série espagnole met en scène un braquage de la Fabrique de la monnaie ?", answer: "La Casa de Papel"),
        QuizQuestion(id: "qz-049", category: .cineSeries, question: "Quel personnage vert et grincheux vit dans un marais ?", answer: "Shrek"),
        QuizQuestion(id: "qz-050", category: .cineSeries, question: "Combien y a-t-il de films dans la saga « Le Seigneur des anneaux » (trilogie originale) ?", answer: "3"),

        // À table
        QuizQuestion(id: "qz-051", category: .aTable, question: "Quel fromage italien est l'ingrédient star du tiramisu ?", answer: "Le mascarpone"),
        QuizQuestion(id: "qz-052", category: .aTable, question: "De quel pays vient la paella ?", answer: "L'Espagne"),
        QuizQuestion(id: "qz-053", category: .aTable, question: "Quel légume est la base du guacamole ?", answer: "L'avocat (techniquement un fruit - accepté)"),
        QuizQuestion(id: "qz-054", category: .aTable, question: "Quelle pâtisserie française porte le nom d'un éclair de génie ? Indice : chocolat ou café.", answer: "L'éclair"),
        QuizQuestion(id: "qz-055", category: .aTable, question: "Quel est l'ingrédient principal du houmous ?", answer: "Les pois chiches"),
        QuizQuestion(id: "qz-056", category: .aTable, question: "De quelle région française vient la quiche ?", answer: "La Lorraine"),
        QuizQuestion(id: "qz-057", category: .aTable, question: "Quel fruit sec est à la base du Nutella (avec le cacao) ?", answer: "La noisette"),
        QuizQuestion(id: "qz-058", category: .aTable, question: "Comment appelle-t-on un plat de pâtes aux œufs, lardons et parmesan ?", answer: "Une carbonara"),
        QuizQuestion(id: "qz-059", category: .aTable, question: "Quelle épice donne sa couleur jaune au curry ?", answer: "Le curcuma"),
        QuizQuestion(id: "qz-060", category: .aTable, question: "Quel pays a inventé les sushis ?", answer: "Le Japon")
    ]
}
