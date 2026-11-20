//
//  CollectionSkinsVueModele.swift
//  GGStats
//
//  Garde la collection de skins de l'utilisateur et la sauvegarde sur le téléphone.
//

import Foundation
import Combine

class CollectionSkinsVueModele: ObservableObject {
    // Skins possédés, triés par champion puis par numéro
    @Published private(set) var skins: [SkinChampion] = []

    private let stockage: UserDefaults
    private let cleStockage = "collectionSkins"

    // Le stockage peut être remplacé (utile pour les tests)
    init(stockage: UserDefaults = .standard) {
        self.stockage = stockage
        charger()
    }

    func possede(_ skin: SkinChampion) -> Bool {
        skins.contains { $0.id == skin.id }
    }

    // Ajoute le skin s'il n'est pas dans la collection, sinon le retire
    func basculer(_ skin: SkinChampion) {
        if possede(skin) {
            skins.removeAll { $0.id == skin.id }
        } else {
            skins.append(skin)
            trier()
        }
        sauvegarder()
    }

    func nombrePossedes(champion cleChampion: String) -> Int {
        skins.filter { $0.cleChampion == cleChampion }.count
    }

    // Skins regroupés par champion, pour l'affichage de la collection
    var parChampion: [(nomChampion: String, skins: [SkinChampion])] {
        var groupes: [(nomChampion: String, skins: [SkinChampion])] = []
        for skin in skins {
            if let dernier = groupes.indices.last, groupes[dernier].nomChampion == skin.nomChampion {
                groupes[dernier].skins.append(skin)
            } else {
                groupes.append((skin.nomChampion, [skin]))
            }
        }
        return groupes
    }

    private func trier() {
        skins.sort {
            if $0.nomChampion != $1.nomChampion {
                return $0.nomChampion.localizedCompare($1.nomChampion) == .orderedAscending
            }
            return $0.numero < $1.numero
        }
    }

    private func charger() {
        guard let donnees = stockage.data(forKey: cleStockage),
              let skinsSauves = try? JSONDecoder().decode([SkinChampion].self, from: donnees) else {
            return
        }
        skins = skinsSauves
        trier()
    }

    private func sauvegarder() {
        if let donnees = try? JSONEncoder().encode(skins) {
            stockage.set(donnees, forKey: cleStockage)
        }
    }
}
