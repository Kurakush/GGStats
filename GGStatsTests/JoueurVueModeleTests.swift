//
//  JoueurVueModeleTests.swift
//  GGStatsTests
//
//  Tests du ViewModel : ce que voient les écrans après une recherche réussie ou ratée.
//

import Foundation
import Testing
@testable import GGStats

extension TestsAvecFauxServeur {

    @Suite("JoueurVueModele")
    @MainActor
    struct JoueurVueModeleTests {

        @Test("Recherche réussie : toutes les données sont remplies")
        func rechercheReussie() async {
            let serveur = FauxServeurRiot()
            let vueModele = JoueurVueModele(api: APIRiot(session: serveur.session))

            await vueModele.rechercher(pseudo: "BbokAri", tag: "lee", file: .soloQ)

            #expect(vueModele.compte?.gameName == "BbokAri")
            #expect(vueModele.invocateur?.summonerLevel == 699)
            #expect(vueModele.classement?.tier == "EMERALD")
            #expect(vueModele.parties.count == 2)
            #expect(vueModele.maitrises.count == 2)
            #expect(vueModele.fileChoisie == .soloQ)
            #expect(vueModele.messageErreur.isEmpty)
            #expect(!vueModele.chargement)
        }

        @Test("Recherche ratée : message d'erreur affiché et chargement terminé")
        func rechercheRatee() async {
            let serveur = FauxServeurRiot()
            serveur.erreur("/riot/account/v1/accounts/by-riot-id/BbokAri/lee", statut: 404)
            let vueModele = JoueurVueModele(api: APIRiot(session: serveur.session))

            await vueModele.rechercher(pseudo: "BbokAri", tag: "lee", file: .flex)

            #expect(vueModele.messageErreur == "Erreur 404 : joueur introuvable ou mauvais serveur.")
            #expect(vueModele.compte == nil)
            #expect(vueModele.parties.isEmpty)
            #expect(!vueModele.chargement)
            #expect(vueModele.fileChoisie == .flex)
        }

        @Test("Une nouvelle recherche efface les résultats et l'erreur précédents")
        func nouvelleRechercheEfface() async {
            let serveur = FauxServeurRiot()
            let vueModele = JoueurVueModele(api: APIRiot(session: serveur.session))

            // 1re recherche OK, puis le même joueur devient introuvable
            await vueModele.rechercher(pseudo: "BbokAri", tag: "lee", file: .soloQ)
            serveur.erreur("/riot/account/v1/accounts/by-riot-id/BbokAri/lee", statut: 404)
            await vueModele.rechercher(pseudo: "BbokAri", tag: "lee", file: .soloQ)

            // Les anciennes données ne doivent pas rester affichées à côté de l'erreur
            #expect(vueModele.compte == nil)
            #expect(vueModele.classement == nil)
            #expect(vueModele.parties.isEmpty)
            #expect(vueModele.maitrises.isEmpty)
            #expect(!vueModele.messageErreur.isEmpty)

            // Puis une recherche qui marche efface l'erreur
            serveur.repondre("/riot/account/v1/accounts/by-riot-id/BbokAri/lee",
                             json: ["puuid": FauxServeurRiot.puuid, "gameName": "BbokAri", "tagLine": "lee"])
            await vueModele.rechercher(pseudo: "BbokAri", tag: "lee", file: .soloQ)
            #expect(vueModele.messageErreur.isEmpty)
            #expect(vueModele.compte != nil)
        }
    }
}
