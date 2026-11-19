//
//  Statistiques.swift
//  GGStats
//
//  Calculs de statistiques partagés par l'app iPhone, la montre et le widget.
//

import Foundation

enum Statistiques {
    // Pourcentage arrondi à l'entier inférieur (58 victoires sur 107 parties -> 54).
    // Renvoie 0 quand il n'y a aucune partie, pour éviter une division par zéro.
    static func pourcentage(valeur: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int(Double(valeur) / Double(total) * 100)
    }
}
