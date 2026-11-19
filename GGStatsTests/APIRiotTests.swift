//
//  APIRiotTests.swift
//  GGStatsTests
//
//  Tests du service APIRiot : on vérifie que les réponses de Riot sont bien transformées
//  en données affichables (parties, classement, maîtrises) et que les erreurs remontent.
//

import Foundation
import Testing
@testable import GGStats

extension TestsAvecFauxServeur {

    @Suite("APIRiot")
    @MainActor
    struct APIRiotTests {

        // MARK: - Recherche LoL

        @Test("SoloQ : profil, classement SoloQ et maîtrises récupérés")
        func rechercheSoloQ() async throws {
            let serveur = FauxServeurRiot()
            let resultat = try await APIRiot(session: serveur.session)
                .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .soloQ)

            #expect(resultat.compte.puuid == FauxServeurRiot.puuid)
            #expect(resultat.compte.gameName == "BbokAri")
            #expect(resultat.invocateur?.summonerLevel == 699)
            #expect(resultat.invocateur?.profileIconId == 7099)

            // Le joueur a SoloQ et Flex : on doit garder uniquement SoloQ
            let classement = try #require(resultat.classement)
            #expect(classement.queueType == "RANKED_SOLO_5x5")
            #expect(classement.tier == "EMERALD")
            #expect(classement.leaguePoints == 64)

            // Maîtrises : noms retrouvés via Data Dragon, champion inconnu ignoré, ordre conservé
            #expect(resultat.maitrises.map(\.nom) == ["Ahri", "Yasuo"])
            #expect(resultat.maitrises.first?.cleImage == "Ahri")
            #expect(resultat.maitrises.first?.points == 250000)
        }

        @Test("Flex : classement Flex et parties filtrées avec la file 440")
        func rechercheFlex() async throws {
            let serveur = FauxServeurRiot()
            let resultat = try await APIRiot(session: serveur.session)
                .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .flex)

            #expect(resultat.classement?.queueType == "RANKED_FLEX_SR")
            #expect(resultat.classement?.tier == "GOLD")

            let urlHistorique = try #require(serveur.requetes.first { $0.url?.path.hasSuffix("/ids") == true }?.url)
            #expect(urlHistorique.query?.contains("queue=440") == true)
            #expect(urlHistorique.query?.contains("count=5") == true)
        }

        @Test("Une partie LoL est transformée en ligne d'historique lisible")
        func transformationPartieLoL() async throws {
            let serveur = FauxServeurRiot()
            let parties = try await APIRiot(session: serveur.session)
                .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .soloQ).parties

            #expect(parties.map(\.id) == ["EUW1_1", "EUW1_2"])

            let victoire = parties[0]
            #expect(victoire.titre == "Ahri")
            #expect(victoire.sousTitre == "10/2/5 - 210 CS")      // CS = sbires (180) + monstres (30)
            #expect(victoire.resultat == "Victoire")
            #expect(victoire.positif)
            #expect(victoire.details == "Durée : 30m 5s")         // 1805 secondes
            #expect(victoire.championIcone == "Ahri")

            let defaite = parties[1]
            #expect(defaite.resultat == "Défaite")
            #expect(!defaite.positif)
        }

        @Test("Les 10 joueurs de la partie sont répartis en deux équipes")
        func joueursDeLaPartie() async throws {
            let serveur = FauxServeurRiot()
            let partie = try #require(try await APIRiot(session: serveur.session)
                .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .soloQ).parties.first)

            #expect(partie.championsPartie.count == 10)
            #expect(partie.championsPartie.filter { $0.teamId == 100 }.count == 5)
            #expect(partie.championsPartie.filter { $0.teamId == 200 }.count == 5)
            // Un joueur sans pseudo dans la réponse Riot est affiché "Joueur"
            #expect(partie.championsPartie.first { $0.id == "AUTRE-9" }?.pseudo == "Joueur")
        }

        // MARK: - Recherche TFT

        @Test("TFT : seulement les parties classées, 5 maximum, Top 4 = positif")
        func rechercheTFT() async throws {
            let serveur = FauxServeurRiot()
            let resultat = try await APIRiot(session: serveur.session)
                .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .tft)

            #expect(resultat.classement == nil)
            // T4 (non classée) est ignorée, puis on s'arrête à 5 parties : T7 et T8 ne sont pas chargées
            #expect(resultat.parties.map(\.id) == ["T1", "T2", "T3", "T5", "T6"])
            #expect(!serveur.cheminsAppeles.contains("/tft/match/v1/matches/T7"))

            let parPlacement = Dictionary(uniqueKeysWithValues: resultat.parties.map { ($0.id, $0) })
            #expect(parPlacement["T1"]?.titre == "Placement #1")
            #expect(parPlacement["T2"]?.resultat == "Top 4")       // 4e = encore dans le top 4
            #expect(parPlacement["T2"]?.positif == true)
            #expect(parPlacement["T3"]?.resultat == "Bottom 4")    // 5e = bottom 4
            #expect(parPlacement["T3"]?.positif == false)
            #expect(parPlacement["T1"]?.sousTitre == "Niveau 9")
            #expect(parPlacement["T1"]?.details == "Joueurs éliminés : 2")
            #expect(resultat.parties.allSatisfy { $0.championsPartie.isEmpty })
        }

        // MARK: - Requêtes envoyées

        @Test("La clé API est envoyée à Riot mais pas à Data Dragon")
        func cleAPIEnvoyeeSeulementARiot() async throws {
            let serveur = FauxServeurRiot()
            _ = try await APIRiot(session: serveur.session)
                .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .soloQ)

            let requetesRiot = serveur.requetes.filter { $0.url?.host?.hasSuffix("api.riotgames.com") == true }
            let requetesDataDragon = serveur.requetes.filter { $0.url?.host == "ddragon.leagueoflegends.com" }

            #expect(!requetesRiot.isEmpty)
            #expect(!requetesDataDragon.isEmpty)
            #expect(requetesRiot.allSatisfy { $0.value(forHTTPHeaderField: "X-Riot-Token")?.hasPrefix("RGAPI-") == true })
            #expect(requetesDataDragon.allSatisfy { $0.value(forHTTPHeaderField: "X-Riot-Token") == nil })
        }

        @Test("Un pseudo avec des espaces est encodé dans l'URL")
        func encodagePseudo() async throws {
            let serveur = FauxServeurRiot(pseudo: "Le Bon Joueur", tag: "EUW")
            let resultat = try await APIRiot(session: serveur.session)
                .rechercherJoueur(pseudo: "Le Bon Joueur", tag: "EUW", file: .soloQ)

            #expect(resultat.compte.gameName == "Le Bon Joueur")
            let urlCompte = try #require(serveur.requetes.first?.url?.absoluteString)
            #expect(urlCompte.contains("/by-riot-id/Le%20Bon%20Joueur/EUW"))
        }

        // MARK: - Erreurs

        @Test("Joueur introuvable : l'erreur 404 remonte avec un message clair")
        func joueurIntrouvable() async {
            let serveur = FauxServeurRiot()
            serveur.erreur("/riot/account/v1/accounts/by-riot-id/BbokAri/lee", statut: 404)

            await #expect {
                try await APIRiot(session: serveur.session)
                    .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .soloQ)
            } throws: { erreur in
                erreur.localizedDescription == "Erreur 404 : joueur introuvable ou mauvais serveur."
            }
        }

        @Test("Clé API expirée : l'erreur 403 remonte")
        func cleExpiree() async {
            let serveur = FauxServeurRiot()
            serveur.erreur("/riot/account/v1/accounts/by-riot-id/BbokAri/lee", statut: 403)

            await #expect {
                try await APIRiot(session: serveur.session)
                    .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .soloQ)
            } throws: { erreur in
                erreur.localizedDescription == "Erreur 403 : clé API invalide ou expirée."
            }
        }

        @Test("Si le profil LoL échoue, la recherche continue sans icône ni niveau")
        func profilIndisponible() async throws {
            let serveur = FauxServeurRiot()
            serveur.erreur("/lol/summoner/v4/summoners/by-puuid/\(FauxServeurRiot.puuid)", statut: 500)

            let resultat = try await APIRiot(session: serveur.session)
                .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .soloQ)

            #expect(resultat.invocateur == nil)
            #expect(resultat.classement != nil)
            #expect(resultat.parties.count == 2)
        }

        @Test("Une réponse JSON inattendue provoque une erreur au lieu d'un crash")
        func jsonInvalide() async {
            let serveur = FauxServeurRiot()
            serveur.repondre("/riot/account/v1/accounts/by-riot-id/BbokAri/lee", json: ["inattendu": true])

            await #expect(throws: DecodingError.self) {
                try await APIRiot(session: serveur.session)
                    .rechercherJoueur(pseudo: "BbokAri", tag: "lee", file: .soloQ)
            }
        }

        // MARK: - Résumé pour le widget

        @Test("Résumé widget : classement et icône, sans charger l'historique")
        func resumeWidget() async throws {
            let serveur = FauxServeurRiot()
            let resume = try await APIRiot(session: serveur.session)
                .rechercherResumeCompte(pseudo: "BbokAri", tag: "lee", file: .soloQ)

            #expect(resume.compte.gameName == "BbokAri")
            #expect(resume.classement?.tier == "EMERALD")
            // L'icône utilise la dernière version de Data Dragon
            #expect(resume.urlIcone?.absoluteString ==
                    "https://ddragon.leagueoflegends.com/cdn/\(FauxServeurRiot.versionDataDragon)/img/profileicon/7099.png")
            // Pas de parties ni de maîtrises : le widget doit rester léger
            #expect(!serveur.cheminsAppeles.contains { $0.contains("/match/") || $0.contains("mastery") })
        }

        @Test("Résumé widget Flex : classement Flex")
        func resumeWidgetFlex() async throws {
            let serveur = FauxServeurRiot()
            let resume = try await APIRiot(session: serveur.session)
                .rechercherResumeCompte(pseudo: "BbokAri", tag: "lee", file: .flex)

            #expect(resume.classement?.queueType == "RANKED_FLEX_SR")
        }

        @Test("Résumé widget : pas d'icône si le profil est indisponible")
        func resumeWidgetSansProfil() async throws {
            let serveur = FauxServeurRiot()
            serveur.erreur("/lol/summoner/v4/summoners/by-puuid/\(FauxServeurRiot.puuid)", statut: 500)

            let resume = try await APIRiot(session: serveur.session)
                .rechercherResumeCompte(pseudo: "BbokAri", tag: "lee", file: .soloQ)

            #expect(resume.invocateur == nil)
            #expect(resume.urlIcone == nil)
            #expect(resume.classement != nil)
        }
    }
}
