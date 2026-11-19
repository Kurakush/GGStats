//
//  LogiqueTests.swift
//  GGStatsTests
//
//  Tests des petites règles métier : files, pourcentages, rangs et messages d'erreur.
//

import SwiftUI
import Testing
@testable import GGStats

@Suite("Files de recherche")
@MainActor
struct FileRechercheTests {

    @Test("Identifiants de file envoyés à Riot")
    func identifiantsRiot() {
        #expect(FileRecherche.soloQ.queueIdLoL == 420)
        #expect(FileRecherche.flex.queueIdLoL == 440)
        #expect(FileRecherche.tft.queueIdLoL == nil)

        #expect(FileRecherche.soloQ.queueTypeClassement == "RANKED_SOLO_5x5")
        #expect(FileRecherche.flex.queueTypeClassement == "RANKED_FLEX_SR")
        #expect(FileRecherche.tft.queueTypeClassement == nil)
    }

    @Test("Les 3 files sont proposées dans l'ordre SoloQ, Flex, TFT")
    func ordre() {
        #expect(FileRecherche.allCases == [.soloQ, .flex, .tft])
        #expect(FileRecherche.allCases.map(\.titre) == ["Ranked Solo/Duo", "Ranked Flex", "Ranked TFT"])
    }
}

@Suite("Statistiques")
@MainActor
struct StatistiquesTests {

    @Test("Calcul du pourcentage", arguments: [
        (valeur: 58, total: 107, attendu: 54),   // arrondi à l'inférieur (54,2 %)
        (valeur: 1, total: 3, attendu: 33),
        (valeur: 2, total: 3, attendu: 66),       // 66,6 % -> 66
        (valeur: 5, total: 5, attendu: 100),
        (valeur: 0, total: 5, attendu: 0)
    ])
    func pourcentage(cas: (valeur: Int, total: Int, attendu: Int)) {
        #expect(Statistiques.pourcentage(valeur: cas.valeur, total: cas.total) == cas.attendu)
    }

    @Test("Aucune partie : 0 % au lieu d'une division par zéro")
    func aucunePartie() {
        #expect(Statistiques.pourcentage(valeur: 0, total: 0) == 0)
    }
}

@Suite("Rangs")
@MainActor
struct RangTests {

    func classement(_ tier: String, _ rank: String) -> Classement {
        Classement(queueType: "RANKED_SOLO_5x5", tier: tier, rank: rank, leaguePoints: 0, wins: 0, losses: 0)
    }

    @Test("Rang affiché avec division", arguments: [
        ("IRON", "IV", "Iron IV"), ("EMERALD", "II", "Emerald II"), ("DIAMOND", "I", "Diamond I")
    ])
    func texteAvecDivision(tier: String, rank: String, attendu: String) {
        #expect(Rang.texte(classement(tier, rank)) == attendu)
    }

    @Test("Master et au-dessus n'ont pas de division", arguments: [
        ("MASTER", "Master"), ("GRANDMASTER", "Grandmaster"), ("CHALLENGER", "Challenger")
    ])
    func texteSansDivision(tier: String, attendu: String) {
        #expect(Rang.texte(classement(tier, "I")) == attendu)
    }

    @Test("Abréviation pour la jauge de l'écran verrouillé", arguments: [
        ("PLATINUM", "III", "P3"), ("EMERALD", "IV", "E4"), ("GOLD", "I", "G1"),
        ("MASTER", "I", "M"), ("GRANDMASTER", "I", "GM"), ("CHALLENGER", "I", "C")
    ])
    func abreviation(tier: String, rank: String, attendu: String) {
        #expect(Rang.abreviation(classement(tier, rank)) == attendu)
    }

    @Test("Chaque tier a sa couleur, un tier inconnu est blanc")
    func couleurs() {
        let tiers = ["IRON", "BRONZE", "SILVER", "GOLD", "PLATINUM", "EMERALD",
                     "DIAMOND", "MASTER", "GRANDMASTER", "CHALLENGER"]
        #expect(tiers.allSatisfy { Rang.couleur($0) != .white })
        #expect(Set(tiers.map { "\(Rang.couleur($0))" }).count == tiers.count)
        #expect(Rang.couleur("INCONNU") == .white)
    }
}

@Suite("Messages d'erreur de l'API")
@MainActor
struct ErreurAPIRiotTests {

    @Test("Codes HTTP traduits pour l'utilisateur", arguments: [
        (401, "Erreur 401 : clé API invalide ou expirée."),
        (403, "Erreur 403 : clé API invalide ou expirée."),
        (404, "Erreur 404 : joueur introuvable ou mauvais serveur."),
        (429, "Erreur 429 : trop de requêtes envoyées."),
        (500, "Erreur HTTP 500 : détail")
    ])
    func messagesHTTP(code: Int, attendu: String) {
        #expect(ErreurAPIRiot.erreurHTTP(code, "détail").localizedDescription == attendu)
    }

    @Test("URL invalide")
    func urlInvalide() {
        #expect(ErreurAPIRiot.mauvaiseURL.localizedDescription == "URL invalide.")
    }
}
