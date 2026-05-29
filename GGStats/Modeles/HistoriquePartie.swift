//
//  HistoriquePartie.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import Foundation

struct HistoriquePartie: Identifiable {
    let id: String
    let titre: String
    let sousTitre: String
    let resultat: String
    let details: String
    let date: String
    let positif: Bool
    let championIcone: String?
    let championsPartie: [ChampionPartie]
}
