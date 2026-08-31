#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Garde : aucun lexique d'alcool dans ce qui s'affiche a l'ecran.

POURQUOI CETTE GARDE EXISTE ICI, ET PAS SEULEMENT DANS LE DEPOT WEB.

Le depot web porte `scripts/check_alcohol_lexicon.mjs` depuis le 2026-08-05. Sa
portee est `bacchana/src` : elle ne couvre pas ce depot, et personne ne s'en
etait avise. Resultat mesure le 2026-08-31 : le mode quiz s'appelait toujours
« Quitte ou Trinque » ici, alors que le web l'avait renomme « Quitte ou Double »
le 5 aout. Le renommage n'avait jamais franchi la frontiere du depot, et la
garde protegeait le fichier qu'on avait corrige, pas le produit.

Ce n'est pas un detail de style. Apple 1.4.3 interdit ce qui « encourage » la
consommation excessive d'alcool, et Play interdit d'en donner une image
favorable, en citant nommement le jeu a gages. Le critere n'est pas le mot
isole, c'est ce que l'ecran donne a lire : une tuile « QUITTE OU TRINQUE » en
premiere page d'un jeu de soiree se lit sans ambiguite. Le positionnement du
produit - aucune boisson nommee, la table decide de ce que vaut une penalite -
est ce qui le rend publiable ; il ne tient que si le binaire le respecte.

CE QUE CETTE GARDE NE VOIT PAS, et qu'il faut savoir :
  - les visuels. L'icone de lancement dessine deux verres qui trinquent, et
    aucune expression reguliere ne lit un dessin. Les deux fichiers qui la
    decrivent sont exemptes NOMMEMENT plus bas, pour que le probleme reste
    visible au lieu d'etre efface d'un coup de commentaire ;
  - le contenu des paquets JSON, garde separement dans `bacchana-content` ;
  - un texte assemble a l'execution a partir de morceaux anodins.

Usage :  python scripts/check_alcohol_lexicon.py
Branchee dans .github/workflows/ci.yml.
"""
import os
import re
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Extensions qui portent du texte affichable ou de la documentation lue par un
# humain. Les images sont hors de portee, voir l'en-tete.
EXTENSIONS = (".swift", ".yml", ".md", ".strings")

# Repertoires sans interet : sorties de build, dependances, copies d'outillage.
IGNORES = {"build", ".build", ".git", ".claude", "DerivedData", "Pods", "Bacchus", "BacchusCore", "BacchusTests"}

# Chaque entree est un couple (etiquette, motif). Les motifs portent leurs
# propres bornes de mot pour eviter les faux positifs : « livrer » contient
# « ivre », « boisson » contient « bois », « verrouille » ne contient PAS
# « verre », et « Coupe-Gorge » n'est pas une « gorgee ».
LEXIQUE = [
    ("trinquer / trinque(nt)", re.compile(r"\btrinqu\w*", re.I)),
    # « bois » est un piege : c'est le verbe ET le materiau. Le motif d'origine,
    # repris du depot web, accusait « un fond brun bois » dans le README - et
    # c'est l'autocontrole plus bas qui l'a vu, pas moi. On ne retient donc
    # « bois » que dans les formes ou il ne peut etre qu'un verbe : « tu bois »,
    # ou une injonction « Bois ! ». Les autres conjugaisons ne sont pas ambigues.
    ("boire / boit / boivent", re.compile(r"\b(boit|boire|boivent)\b", re.I)),
    ("bois (verbe)", re.compile(r"\btu bois\b|\bbois\s*[!?]", re.I)),
    # La prose accentuee seulement : `gorgees` sans accent est un identifiant
    # technique du schema de penalite, jamais affiche tel quel.
    ("gorgee(s), prose accentuee", re.compile(r"gorg[ée]es?\b", re.I)),
    ("cul sec", re.compile(r"cul[- ]sec", re.I)),
    ("verre(s), contenant a boire", re.compile(r"\bverres?\b", re.I)),
    ("shot(s) comme mesure d'alcool", re.compile(r"(?<!-)\bshots?\b", re.I)),
    ("alcool / alcoolise", re.compile(r"\balcool\w*", re.I)),
    ("biere / vin / vodka / whisky / tequila / rhum",
     re.compile(r"\b(bi[èe]res?|vins?|vodka|whisky|tequila|rhum)\b", re.I)),
    ("apero", re.compile(r"\bap[ée]ros?\b", re.I)),
    # « cuite » au sens d'ivresse SEULEMENT. Sans l'article, la garde accusait
    # « des pates trop cuites » dans une question de classement.
    ("bourre / murge / prendre une cuite",
     re.compile(r"\b(bourr[ée]s?|murges?|(une|la|sa) cuite)\b", re.I)),
    ("tchin", re.compile(r"\btchin\w*", re.I)),
]

# Le CHANGELOG raconte les faits AU MOMENT ou ils ont eu lieu. Une entree qui
# dit « mode Quitte ou Trinque ajoute » est vraie pour sa date, et la reecrire
# effacerait l'histoire du renommage au lieu de la documenter.
FICHIERS_HORS_PORTEE = {"CHANGELOG.md"}

# Une ligne qui AFFIRME l'absence d'alcool est le positionnement recherche, pas
# une violation. Sans cette exemption la garde accuse la documentation qui la
# justifie, et une garde qui crie a tort finit desactivee.
NEGATIONS = re.compile(
    r"\b(z[ée]ro|aucun\w*|jamais|sans|pas d[e'’]|ne \w+ (pas|plus)|interdit\w*|purg[ée]\w*|abstrait\w*)\b",
    re.I,
)

# Exemptions NOMMEES, une par une, avec leur raison. Pas de motif large : une
# exemption qu'on ne peut pas justifier en une ligne est une porte ouverte.
EXEMPTIONS = {
    # Valeurs brutes des enums de penalite, internes au schema, jamais rendues a
    # l'ecran : le texte affiche est toujours « N penalite(s) ».
    "gorgees",
    "shots",
    "shot",
    "sips",
}

FICHIERS_EXEMPTES = {
    # Rien pour l'instant. Les exemptions se posent une par une, avec leur
    # raison ecrite : une liste vide vaut mieux qu'une exemption commode.
}


def autocontrole():
    """Verifie que la garde marche AVANT de s'en servir.

    Pourquoi ce bloc existe, et il a ete paye TROIS FOIS dans la meme journee.

    Un motif ecrit a travers deux couches d'echappement - un script qui ecrit un
    fichier - peut recevoir un antislash-b transforme en CARACTERE DE CONTROLE
    backspace (0x08) au lieu d'une echappement de regex. Le fichier se lit
    normalement dans un editeur, la ligne parait juste, et le motif ne
    correspond plus jamais a rien.

    C'est arrive a `git_guard` le matin, puis a `check_tile_ink`, puis a la
    regle de negation de ce fichier - qui ne reconnaissait plus « jamais » ni
    « zero », et faisait accuser par la garde la documentation qui la justifie.
    Une garde qui crie a tort finit desactivee : ce defaut-la est le plus
    couteux de tous, parce qu'il se presente comme un exces de zele.

    Se fier a son attention a echoue trois fois. On mesure.
    """
    ennuis = []

    brut = open(os.path.abspath(__file__), encoding="utf-8").read()
    parasites = sorted({hex(ord(c)) for c in brut if ord(c) < 32 and c not in "\n\t\r"})
    if parasites:
        ennuis.append("caracteres de controle dans ce fichier : %s" % ", ".join(parasites))

    epreuves = [
        "on trinque ce soir",
        "il boit trop",
        "tu bois cul sec",
        "prends une gorgée",
        "cul sec",
        "un verre de plus",
        "deux shots",
        "de l'alcool fort",
        "une bière fraiche",
        "un apéro",
        "il a pris une cuite",
        "tchin les amis",
    ]
    for phrase in epreuves:
        if not any(m.search(phrase) for _, m in LEXIQUE):
            ennuis.append("aucun motif n'attrape : %s" % phrase)

    for phrase in ["zéro référence à l'alcool", "jamais de gorgées nommées", "sans alcool"]:
        if not NEGATIONS.search(phrase):
            ennuis.append("la negation ne reconnait pas : %s" % phrase)

    # Et l'inverse : une phrase anodine ne doit declencher personne.
    for phrase in ["des pates trop cuites", "un fond brun bois", "le Coupe-Gorge"]:
        if any(m.search(phrase) for _, m in LEXIQUE):
            ennuis.append("faux positif sur : %s" % phrase)

    return ennuis


def fichiers():
    for base, dossiers, noms in os.walk(RACINE):
        dossiers[:] = [d for d in dossiers if d not in IGNORES]
        for n in noms:
            if n.endswith(EXTENSIONS):
                yield os.path.join(base, n)


def main():
    ennuis = autocontrole()
    if ennuis:
        print("\nLA GARDE ELLE-MEME EST CASSEE - %d probleme(s).\n" % len(ennuis))
        print("Elle ne peut donc rien prouver, et un vert de sa part serait un")
        print("mensonge. On echoue ici plutot que d'annoncer que tout va bien.\n")
        for e in ennuis:
            print("  %s" % e)
        return 2

    fautes = []
    lus = 0
    for chemin in fichiers():
        # La garde ne s'accuse pas elle-meme : son lexique EST une liste de mots
        # interdits, et elle doit pouvoir les nommer pour les chercher.
        if os.path.abspath(chemin) == os.path.abspath(__file__):
            continue
        if os.path.basename(chemin) in FICHIERS_HORS_PORTEE:
            continue
        if os.path.relpath(chemin, RACINE).replace(os.sep, "/") in FICHIERS_EXEMPTES:
            continue
        try:
            texte = open(chemin, encoding="utf-8").read()
        except (UnicodeDecodeError, OSError):
            continue
        lus += 1
        toutes = texte.split("\n")
        for n, ligne in enumerate(toutes, 1):
            for etiquette, motif in LEXIQUE:
                trouve = motif.search(ligne)
                if not trouve:
                    continue
                if trouve.group(0).lower() in EXEMPTIONS:
                    continue
                # La negation se lit sur un VOISINAGE, pas sur la seule ligne.
                # Un paragraphe de README ecrit « Zero reference alcool » a la
                # premiere ligne et « regles Apple et Play sur le contenu lie a
                # l'alcool » a la quatrieme : c'est une seule phrase pour un
                # lecteur, et deux lignes pour un tableau. Sans cette fenetre, la
                # garde exigeait de tordre la prose pour la satisfaire - ce qui
                # est le debut de la fin pour une garde.
                voisinage = "\n".join(toutes[max(0, n - 4):n + 2])
                if NEGATIONS.search(voisinage):
                    continue
                rel = os.path.relpath(chemin, RACINE).replace(os.sep, "/")
                fautes.append((rel, n, etiquette, ligne.strip()[:96]))
                break

    if fautes:
        print("\nLexique d'alcool dans le code - %d occurrence(s).\n" % len(fautes))
        print("Le produit se tient sur une promesse : aucune boisson nommee, la")
        print("table decide de ce que vaut une penalite. C'est ce qui le rend")
        print("publiable au regard d'Apple 1.4.3 et de la politique Play sur les")
        print("substances reglementees. Chaque ligne ci-dessous la contredit.\n")
        for f, n, etiquette, ligne in fautes:
            print("  %s:%d  [%s]" % (f, n, etiquette))
            print("      %s" % ligne)
        return 1

    print("Lexique d'alcool : %d fichiers verifies, aucune occurrence." % lus)
    return 0


if __name__ == "__main__":
    sys.exit(main())
