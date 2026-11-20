//
//  SkinChampion.swift
//  GGStats
//
//  Un skin de champion venant de Data Dragon.
//  L'API Riot ne donne pas les skins possédés par un joueur : la collection est donc
//  remplie à la main dans l'app, et on garde ici juste ce qu'il faut pour l'afficher.
//

import Foundation

struct SkinChampion: Identifiable, Codable, Hashable {
    // id Data Dragon du skin, ex : "103001" (champion 103, skin n°1)
    let id: String
    let nom: String
    // clé du champion utilisée dans les URL d'images, ex : "Ahri", "MonkeyKing"
    let cleChampion: String
    let nomChampion: String
    // numéro du skin pour ce champion (0 = skin de base)
    let numero: Int

    // Image verticale (308x560), adaptée à une grille
    var urlChargement: URL? {
        URL(string: "https://ddragon.leagueoflegends.com/cdn/img/champion/loading/\(cleChampion)_\(numero).jpg")
    }

    // Grande image horizontale
    var urlSplash: URL? {
        URL(string: "https://ddragon.leagueoflegends.com/cdn/img/champion/splash/\(cleChampion)_\(numero).jpg")
    }
}

// Un champion de la liste Data Dragon, pour parcourir le catalogue de skins
struct ChampionCatalogue: Identifiable, Hashable {
    let id: String   // clé Data Dragon, ex : "Ahri"
    let nom: String

    func urlIcone(version: String) -> URL? {
        URL(string: "https://ddragon.leagueoflegends.com/cdn/\(version)/img/champion/\(id).png")
    }
}
