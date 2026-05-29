//
//  FileRecherche.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import Foundation

enum FileRecherche: String, CaseIterable, Identifiable {
    case soloQ = "SoloQ"
    case flex = "Flex"
    case tft = "TFT"

    var id: String {
        rawValue
    }

    var titre: String {
        switch self {
        case .soloQ:
            return "Ranked Solo/Duo"
        case .flex:
            return "Ranked Flex"
        case .tft:
            return "Ranked TFT"
        }
    }

    var queueIdLoL: Int? {
        switch self {
        case .soloQ:
            return 420
        case .flex:
            return 440
        case .tft:
            return nil
        }
    }

    var queueTypeClassement: String? {
        switch self {
        case .soloQ:
            return "RANKED_SOLO_5x5"
        case .flex:
            return "RANKED_FLEX_SR"
        case .tft:
            return nil
        }
    }
}
