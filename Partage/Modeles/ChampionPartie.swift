//
//  ChampionPartie.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import Foundation

struct ChampionPartie: Identifiable {
    let id: String
    let pseudo: String
    let champion: String
    let kills: Int
    let deaths: Int
    let assists: Int
    let teamId: Int
    let win: Bool
}
