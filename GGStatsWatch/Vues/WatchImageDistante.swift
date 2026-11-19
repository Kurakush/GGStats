//
//  WatchImageDistante.swift
//  GGStatsWatch
//
//  Petits utilitaires d'affichage d'images Data Dragon sur la montre.
//

import SwiftUI

// Construit les URLs des images Data Dragon (même version que celle utilisée côté iPhone)
enum URLsDataDragon {
    static let version = "15.12.1"

    static func champion(_ cle: String) -> URL? {
        URL(string: "https://ddragon.leagueoflegends.com/cdn/\(version)/img/champion/\(cle).png")
    }

    static func iconeProfil(_ id: Int) -> URL? {
        URL(string: "https://ddragon.leagueoflegends.com/cdn/\(version)/img/profileicon/\(id).png")
    }
}

// Image ronde chargée depuis Internet, avec un indicateur pendant le chargement
struct WatchImageDistante: View {
    let url: URL?
    let taille: CGFloat

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ProgressView()
        }
        .frame(width: taille, height: taille)
        .clipShape(Circle())
    }
}
