//
//  Classement.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import Foundation

struct Classement: Codable {
    let queueType: String
    let tier: String
    let rank: String
    let leaguePoints: Int
    let wins: Int
    let losses: Int
}
