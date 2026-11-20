//
//  CollectionSkinsTests.swift
//  GGStatsTests
//
//  Tests de la collection de skins : ajout / retrait, tri, sauvegarde,
//  et lecture des skins depuis Data Dragon.
//

import Foundation
import Testing
@testable import GGStats

@Suite("Collection de skins")
struct CollectionSkinsTests {

    // Un stockage vide, propre à chaque test
    func stockageVide() -> UserDefaults {
        let nom = "tests-collection-\(UUID().uuidString)"
        let stockage = UserDefaults(suiteName: nom)!
        stockage.removePersistentDomain(forName: nom)
        return stockage
    }

    func skin(_ champion: String, _ numero: Int) -> SkinChampion {
        SkinChampion(id: "\(champion)\(numero)", nom: "\(champion) \(numero)",
                     cleChampion: champion, nomChampion: champion, numero: numero)
    }

    @Test("Basculer ajoute puis retire un skin")
    func basculer() {
        let collection = CollectionSkinsVueModele(stockage: stockageVide())
        let ahri = skin("Ahri", 1)

        collection.basculer(ahri)
        #expect(collection.possede(ahri))
        #expect(collection.nombrePossedes(champion: "Ahri") == 1)

        collection.basculer(ahri)
        #expect(!collection.possede(ahri))
        #expect(collection.skins.isEmpty)
    }

    @Test("Les skins sont triés et groupés par champion")
    func triEtGroupes() {
        let collection = CollectionSkinsVueModele(stockage: stockageVide())
        collection.basculer(skin("Yasuo", 2))
        collection.basculer(skin("Ahri", 5))
        collection.basculer(skin("Ahri", 1))

        #expect(collection.skins.map(\.id) == ["Ahri1", "Ahri5", "Yasuo2"])
        #expect(collection.parChampion.map(\.nomChampion) == ["Ahri", "Yasuo"])
        #expect(collection.parChampion.first?.skins.count == 2)
    }

    @Test("La collection est retrouvée au prochain lancement")
    func sauvegarde() {
        let stockage = stockageVide()
        CollectionSkinsVueModele(stockage: stockage).basculer(skin("Ahri", 1))

        let rechargee = CollectionSkinsVueModele(stockage: stockage)
        #expect(rechargee.skins.map(\.id) == ["Ahri1"])
    }

    @Test("URL des images construites avec la clé du champion et le numéro")
    func urlsImages() {
        let s = skin("MonkeyKing", 3)
        #expect(s.urlChargement?.absoluteString == "https://ddragon.leagueoflegends.com/cdn/img/champion/loading/MonkeyKing_3.jpg")
        #expect(s.urlSplash?.absoluteString == "https://ddragon.leagueoflegends.com/cdn/img/champion/splash/MonkeyKing_3.jpg")
    }
}

extension TestsAvecFauxServeur {

    @Suite("Catalogue de skins")
    struct CatalogueSkinsTests {

        @Test("Catalogue des champions trié par nom")
        func catalogue() async throws {
            let serveur = FauxServeurRiot()
            let resultat = try await APIRiot(session: serveur.session).recupererCatalogueChampions()

            #expect(resultat.version == FauxServeurRiot.versionDataDragon)
            #expect(resultat.champions.map(\.id) == ["Ahri", "Yasuo"])
        }

        @Test("Skins d'un champion : le skin de base est renommé")
        func skinsChampion() async throws {
            let serveur = FauxServeurRiot()
            let version = FauxServeurRiot.versionDataDragon
            serveur.repondre("/cdn/\(version)/data/fr_FR/champion/Ahri.json", json: ["data": ["Ahri": ["skins": [
                ["id": "103000", "num": 0, "name": "default"],
                ["id": "103001", "num": 1, "name": "Ahri dynastique"]
            ]]]])

            let skins = try await APIRiot(session: serveur.session)
                .recupererSkins(champion: ChampionCatalogue(id: "Ahri", nom: "Ahri"), version: version)

            #expect(skins.map(\.nom) == ["Ahri (classique)", "Ahri dynastique"])
            #expect(skins.map(\.numero) == [0, 1])
            #expect(skins.allSatisfy { $0.cleChampion == "Ahri" })
        }
    }
}
