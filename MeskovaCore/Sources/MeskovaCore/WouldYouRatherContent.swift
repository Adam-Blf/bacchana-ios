import Foundation

/// One dilemma for "Tu préfères". Mirrors `la-taverne/src/content/wouldYouRather.ts`;
/// keep both in sync when the deck changes.
public struct WouldYouRatherQuestion: Identifiable, Equatable, Sendable {
    public let id: String
    public let optionA: String
    public let optionB: String

    public init(id: String, optionA: String, optionB: String) {
        self.id = id
        self.optionA = optionA
        self.optionB = optionB
    }
}

/// Tu préfères is an embedded game mode: no content pack, no JSON source.
/// 84 dilemmes 100 % originaux, store-safe : jamais d'alcool nommé, uniquement
/// des « pénalités ».
public enum WouldYouRatherContent {
    public static let questions: [WouldYouRatherQuestion] = [
        WouldYouRatherQuestion(id: "wyr-001", optionA: "Avoir le hoquet toute ta vie", optionB: "Éternuer 20 fois par jour"),
        WouldYouRatherQuestion(id: "wyr-002", optionA: "Pouvoir voler mais seulement 30cm du sol", optionB: "Marcher sur l'eau seulement la nuit"),
        WouldYouRatherQuestion(id: "wyr-003", optionA: "Parler comme une célébrité étrangère toute ta vie", optionB: "Avoir un accent bizarre incurable"),
        WouldYouRatherQuestion(id: "wyr-004", optionA: "Cheveux qui changent de couleur selon ton humeur", optionB: "Peau qui rougit chaque fois que tu mens"),
        WouldYouRatherQuestion(id: "wyr-005", optionA: "Vivre dans une maison faite uniquement de portes vitrées", optionB: "Vivre dans une maison faite uniquement d'escaliers en colimaçon"),
        WouldYouRatherQuestion(id: "wyr-006", optionA: "Porter des chaussures trop petites toute ta vie", optionB: "Porter des chaussures trop grandes toute ta vie"),
        WouldYouRatherQuestion(id: "wyr-007", optionA: "Avoir des mains de T-Rex", optionB: "Avoir des jambes très courtes style mascotte"),
        WouldYouRatherQuestion(id: "wyr-008", optionA: "Manger uniquement des pâtes à vie", optionB: "Manger uniquement du pain complet à vie"),
        WouldYouRatherQuestion(id: "wyr-009", optionA: "Avoir un klaxon à la place de la voix", optionB: "Crier comme un bébé toujours"),
        WouldYouRatherQuestion(id: "wyr-010", optionA: "Oublier le nom de quelqu'un immédiatement après", optionB: "Confondre toujours les visages"),
        WouldYouRatherQuestion(id: "wyr-011", optionA: "Vivre en noir et blanc", optionB: "Vivre en rose fluo permanent"),
        WouldYouRatherQuestion(id: "wyr-012", optionA: "Avoir une queue visible permanente", optionB: "Avoir des oreilles pointues de lutin"),
        WouldYouRatherQuestion(id: "wyr-013", optionA: "Rire sans t'arrêter dans les moments graves", optionB: "Ne plus jamais pouvoir rire"),
        WouldYouRatherQuestion(id: "wyr-014", optionA: "Marcher à reculons toujours", optionB: "Marcher de travers comme un crabe"),
        WouldYouRatherQuestion(id: "wyr-015", optionA: "Avoir une sonnette à la place de la voix", optionB: "Avoir un bruiteur d'ascenseur comme voix"),
        WouldYouRatherQuestion(id: "wyr-016", optionA: "Dormir debout comme un cheval", optionB: "Dormir appuyé contre un mur"),
        WouldYouRatherQuestion(id: "wyr-017", optionA: "Avoir des cornes ornementales", optionB: "Avoir une corne de licorne sur le front"),
        WouldYouRatherQuestion(id: "wyr-018", optionA: "Voir en rayons X toujours", optionB: "Voir en caméra thermique"),
        WouldYouRatherQuestion(id: "wyr-019", optionA: "Ta voix descend d'une octave par an", optionB: "Ta voix monte d'une octave par an"),
        WouldYouRatherQuestion(id: "wyr-020", optionA: "Avoir des griffes de chat", optionB: "Avoir des crocs de vampire"),
        WouldYouRatherQuestion(id: "wyr-021", optionA: "Danser involontairement chaque jeudi", optionB: "Danser involontairement dès que quelqu'un crie"),
        WouldYouRatherQuestion(id: "wyr-022", optionA: "Changer de taille au hasard entre 10cm et 3m", optionB: "Peser au hasard entre 10kg et 200kg"),
        WouldYouRatherQuestion(id: "wyr-023", optionA: "Aimanter les objets métalliques", optionB: "Générer des étincelles en frottant tes mains"),
        WouldYouRatherQuestion(id: "wyr-024", optionA: "Avoir des ailes de papillon", optionB: "Avoir des ailes de chauve-souris"),
        WouldYouRatherQuestion(id: "wyr-025", optionA: "Avoir une bande sonore épique qui te suit", optionB: "Avoir des effets sonores de jeu vidéo aléatoires"),
        WouldYouRatherQuestion(id: "wyr-026", optionA: "Parler par télépathie mais très fort", optionB: "Crier toujours en chuchotant"),
        WouldYouRatherQuestion(id: "wyr-027", optionA: "Avoir les yeux qui brillent la nuit", optionB: "Avoir les yeux qui changent avec tes émotions"),
        WouldYouRatherQuestion(id: "wyr-028", optionA: "Avoir une moustache permanente", optionB: "Avoir une barbe pixelisée"),
        WouldYouRatherQuestion(id: "wyr-029", optionA: "Sentir la fraise toute ta vie", optionB: "Sentir l'essence toute ta vie"),
        WouldYouRatherQuestion(id: "wyr-030", optionA: "Avoir des tentacules à la place des bras", optionB: "Avoir des tentacules à la place des jambes"),
        WouldYouRatherQuestion(id: "wyr-031", optionA: "Rougir violemment face à quelqu'un qui te plaît", optionB: "Transpirer dès que tu stresses"),
        WouldYouRatherQuestion(id: "wyr-032", optionA: "Vivre dans un monde en Sims pixelisés", optionB: "Vivre dans un monde en animé 2D"),
        WouldYouRatherQuestion(id: "wyr-033", optionA: "Avoir un seul sourcil permanent", optionB: "Ne pas avoir de sourcils du tout"),
        WouldYouRatherQuestion(id: "wyr-034", optionA: "Avoir des pieds de canard", optionB: "Avoir des mains de singe"),
        WouldYouRatherQuestion(id: "wyr-035", optionA: "Avoir la voix qui se brise quand tu cries", optionB: "Crier comme une fillette toujours"),
        WouldYouRatherQuestion(id: "wyr-036", optionA: "Que ton crush te voie au pire moment possible", optionB: "Texter par erreur un truc cringe à ton crush"),
        WouldYouRatherQuestion(id: "wyr-037", optionA: "Avoir une tache noire entre les dents une journée", optionB: "Marcher toute la journée avec du PQ sous la chaussure"),
        WouldYouRatherQuestion(id: "wyr-038", optionA: "Croiser ton ex au pire moment", optionB: "Que ton crush arrive juste à ce moment-là"),
        WouldYouRatherQuestion(id: "wyr-039", optionA: "Avoir le hoquet en pleine présentation", optionB: "Bafouiller devant toute la classe"),
        WouldYouRatherQuestion(id: "wyr-040", optionA: "Appeler ta prof maman une fois", optionB: "Crier le nom de ton crush devant tout le monde"),
        WouldYouRatherQuestion(id: "wyr-041", optionA: "Avoir une verrue visible sur le visage", optionB: "Avoir une cicatrice bizarre bien visible"),
        WouldYouRatherQuestion(id: "wyr-042", optionA: "Envoyer un message cringe à ton crush", optionB: "Lui envoyer une photo pas terrible de toi"),
        WouldYouRatherQuestion(id: "wyr-043", optionA: "Avoir une voix très grave pendant un mois", optionB: "Avoir la voix d'un enfant de 5 ans pendant un mois"),
        WouldYouRatherQuestion(id: "wyr-044", optionA: "Que ton groupe apprenne un secret gênant sur toi", optionB: "Apprendre un secret gênant sur ton meilleur ami"),
        WouldYouRatherQuestion(id: "wyr-045", optionA: "Avoir le visage plein de boutons une semaine", optionB: "Avoir une coupe de cheveux ratée un mois"),
        WouldYouRatherQuestion(id: "wyr-046", optionA: "Oublier le prénom de ton rendez-vous", optionB: "L'appeler par le prénom de ton ex"),
        WouldYouRatherQuestion(id: "wyr-047", optionA: "Avoir des tics nerveux visibles quand tu stresses", optionB: "Bafouiller complètement en parlant"),
        WouldYouRatherQuestion(id: "wyr-048", optionA: "Te sentir observé par quelqu'un qui te plaît", optionB: "Te sentir observé par quelqu'un pas ton type"),
        WouldYouRatherQuestion(id: "wyr-049", optionA: "Voir ton crush avec quelqu'un d'autre", optionB: "Que ton crush te voie avec quelqu'un d'autre"),
        WouldYouRatherQuestion(id: "wyr-050", optionA: "Trébucher devant la personne qui te plaît", optionB: "Renverser ton verre sur elle"),
        WouldYouRatherQuestion(id: "wyr-051", optionA: "Transpirer beaucoup à un premier rendez-vous", optionB: "Bafouiller et rougir sans t'arrêter"),
        WouldYouRatherQuestion(id: "wyr-052", optionA: "Avoir un vieux post cringe qui refait surface", optionB: "Avoir une photo de classe humiliante qui circule"),
        WouldYouRatherQuestion(id: "wyr-053", optionA: "Que ton crush voie une vidéo embarrassante de toi", optionB: "Que ton crush lise tes vieux messages cringes"),
        WouldYouRatherQuestion(id: "wyr-054", optionA: "Rire nerveusement dans un moment sérieux", optionB: "Pleurer devant tout le monde pour rien"),
        WouldYouRatherQuestion(id: "wyr-055", optionA: "Avoir constamment les joues rouges", optionB: "Avoir une expression gênante figée sur le visage"),
        WouldYouRatherQuestion(id: "wyr-056", optionA: "Appeler quelqu'un par le nom de son ex", optionB: "Oublier complètement le prénom d'un proche"),
        WouldYouRatherQuestion(id: "wyr-057", optionA: "Craquer pour ton boss", optionB: "Craquer pour ton meilleur ami déjà en couple"),
        WouldYouRatherQuestion(id: "wyr-058", optionA: "Avoir un crush sur un cousin lointain", optionB: "Avoir un crush sur la meilleure amie de ton ex"),
        WouldYouRatherQuestion(id: "wyr-059", optionA: "Avoir un crush beaucoup plus jeune", optionB: "Avoir un crush beaucoup plus vieux"),
        WouldYouRatherQuestion(id: "wyr-060", optionA: "Flasher sur le rendez-vous de ton meilleur ami", optionB: "Flasher sur l'ex de ta sœur"),
        WouldYouRatherQuestion(id: "wyr-061", optionA: "Envoyer un message gênant à tout ton groupe", optionB: "Envoyer ce même message à ta mère"),
        WouldYouRatherQuestion(id: "wyr-062", optionA: "Avoir une trace de sueur permanente sur ta chemise", optionB: "Avoir une tache bien visible sur ton pantalon"),
        WouldYouRatherQuestion(id: "wyr-063", optionA: "Dire je t'aime par erreur à la caissière", optionB: "Dire je t'aime par erreur au livreur"),
        WouldYouRatherQuestion(id: "wyr-064", optionA: "Avoir un accent bizarre quand tu es nerveux", optionB: "Bégayer dès que tu parles à quelqu'un"),
        WouldYouRatherQuestion(id: "wyr-065", optionA: "Ne plus jamais ressentir le frisson d'un crush", optionB: "Tomber amoureux toutes les semaines"),
        WouldYouRatherQuestion(id: "wyr-066", optionA: "Te trouver irrésistible en permanence", optionB: "Penser que personne ne te remarque jamais"),
        WouldYouRatherQuestion(id: "wyr-067", optionA: "Que ton crush t'envoie un message flirty par erreur", optionB: "Que ton crush like toutes tes vieilles photos"),
        WouldYouRatherQuestion(id: "wyr-068", optionA: "Avouer ton crush et te prendre un râteau", optionB: "Ne jamais oser et le regretter à vie"),
        WouldYouRatherQuestion(id: "wyr-069", optionA: "Embrasser quelqu'un et que ce soit très gênant", optionB: "Rater le moment parfait pour un premier baiser"),
        WouldYouRatherQuestion(id: "wyr-070", optionA: "Que ton ex débarque avec sa nouvelle copine", optionB: "Que ton ex débarque au bras de ta meilleure amie"),
        WouldYouRatherQuestion(id: "wyr-071", optionA: "Tenter ta chance au risque de perdre l'amitié", optionB: "Garder l'amitié et enterrer tes sentiments"),
        WouldYouRatherQuestion(id: "wyr-072", optionA: "Avoir un crush sur quelqu'un d'inaccessible", optionB: "Avoir un crush sur quelqu'un que tes amis détestent"),
        WouldYouRatherQuestion(id: "wyr-073", optionA: "Être attiré par deux personnes à la fois", optionB: "Que deux personnes soient attirées par toi en même temps"),
        WouldYouRatherQuestion(id: "wyr-074", optionA: "Un premier rendez-vous parfait mais sans aucun courant", optionB: "Un premier rendez-vous catastrophique mais plein de papillons"),
        WouldYouRatherQuestion(id: "wyr-075", optionA: "Que ton crush connaisse tous tes secrets", optionB: "Connaître tous les secrets de ton crush"),
        WouldYouRatherQuestion(id: "wyr-076", optionA: "Devoir choisir entre ta carrière et l'amour", optionB: "Devoir choisir entre ta liberté et une relation sérieuse"),
        WouldYouRatherQuestion(id: "wyr-077", optionA: "Que ton crush voie ta liste de crushs passés", optionB: "Voir la liste des crushs passés de ton crush"),
        WouldYouRatherQuestion(id: "wyr-078", optionA: "Être obsédé par une célébrité inatteignable", optionB: "Être obsédé par quelqu'un que tu devrais éviter"),
        WouldYouRatherQuestion(id: "wyr-079", optionA: "Vouloir avancer alors que l'autre freine", optionB: "Que l'autre veuille avancer alors que tu freines"),
        WouldYouRatherQuestion(id: "wyr-080", optionA: "Que ton journal intime soit lu par ton groupe", optionB: "Que ton journal intime soit lu par tes parents"),
        WouldYouRatherQuestion(id: "wyr-081", optionA: "Déclarer ta flamme en public et te faire jeter", optionB: "Apprendre que ton crush t'aimait mais a abandonné"),
        WouldYouRatherQuestion(id: "wyr-082", optionA: "Avoir du mal à dire ce que tu ressens", optionB: "Tout dire trop vite et faire fuir les gens"),
        WouldYouRatherQuestion(id: "wyr-083", optionA: "Te faire surprendre en train de mater ton crush", optionB: "Surprendre ton crush en train de te mater"),
        WouldYouRatherQuestion(id: "wyr-084", optionA: "Choisir quelqu'un d'ultra attirant mais distant", optionB: "Choisir quelqu'un de banal mais fou de toi")
    ]
}
