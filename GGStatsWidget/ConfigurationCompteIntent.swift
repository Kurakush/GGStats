//
//  ConfigurationCompteIntent.swift
//  GGStatsWidget
//
//  Paramètres que l'utilisateur règle via "Modifier le widget" (appui long sur le widget).
//

import AppIntents
import WidgetKit

// Les files proposées dans le widget.
// Pas de TFT : l'API utilisée par l'app ne récupère pas de classement TFT.
enum FileWidget: String, AppEnum {
    case soloQ
    case flex

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "File"

    static var caseDisplayRepresentations: [FileWidget: DisplayRepresentation] = [
        .soloQ: "Ranked Solo/Duo",
        .flex: "Ranked Flex"
    ]

    // Conversion vers l'enum partagée avec l'app
    var fileRecherche: FileRecherche {
        switch self {
        case .soloQ: return .soloQ
        case .flex: return .flex
        }
    }
}

struct ConfigurationCompteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Compte Riot"
    static var description = IntentDescription("Choisis le compte League of Legends à suivre.")

    @Parameter(title: "Riot ID (Pseudo#TAG)", default: "")
    var riotID: String

    @Parameter(title: "File", default: .soloQ)
    var file: FileWidget
}
