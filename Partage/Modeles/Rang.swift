//
//  Rang.swift
//  GGStats
//
//  Mise en forme des rangs Riot, partagée par le widget (et utilisable par l'app et la montre).
//

import SwiftUI

// Mise en forme des rangs Riot (les tiers arrivent en majuscules : "EMERALD", "GRANDMASTER"…)
enum Rang {
    private static let tiersSansDivision = ["MASTER", "GRANDMASTER", "CHALLENGER"]

    static func texte(_ classement: Classement) -> String {
        let tier = classement.tier.capitalized
        // Master et au-dessus n'ont pas de division (l'API renvoie quand même "I")
        return tiersSansDivision.contains(classement.tier) ? tier : "\(tier) \(classement.rank)"
    }

    static func abreviation(_ classement: Classement) -> String {
        switch classement.tier {
        case "GRANDMASTER": return "GM"
        case "CHALLENGER": return "C"
        case "MASTER": return "M"
        default: return "\(classement.tier.prefix(1))\(chiffre(classement.rank))"
        }
    }

    private static func chiffre(_ rang: String) -> String {
        ["I": "1", "II": "2", "III": "3", "IV": "4"][rang] ?? rang
    }

    static func couleur(_ tier: String) -> Color {
        switch tier {
        case "IRON": return Color(red: 0.55, green: 0.50, blue: 0.48)
        case "BRONZE": return Color(red: 0.80, green: 0.50, blue: 0.30)
        case "SILVER": return Color(red: 0.78, green: 0.82, blue: 0.86)
        case "GOLD": return Color(red: 0.95, green: 0.78, blue: 0.30)
        case "PLATINUM": return Color(red: 0.30, green: 0.80, blue: 0.75)
        case "EMERALD": return Color(red: 0.25, green: 0.85, blue: 0.50)
        case "DIAMOND": return Color(red: 0.45, green: 0.65, blue: 1.00)
        case "MASTER": return Color(red: 0.75, green: 0.45, blue: 1.00)
        case "GRANDMASTER": return Color(red: 1.00, green: 0.40, blue: 0.40)
        case "CHALLENGER": return Color(red: 0.55, green: 0.90, blue: 1.00)
        default: return .white
        }
    }
}
