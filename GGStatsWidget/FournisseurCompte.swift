//
//  FournisseurCompte.swift
//  GGStatsWidget
//
//  Le "provider" dit à iOS quoi afficher et quand rafraîchir le widget.
//

import WidgetKit
import UIKit

// Ce qu'affiche le widget à un instant donné
struct EntreeCompte: TimelineEntry {
    enum Etat {
        case aConfigurer
        case erreur(String)
        case donnees(ResumeCompte)
    }

    let date: Date
    let etat: Etat
}

// Les infos du compte déjà prêtes à afficher
struct ResumeCompte {
    let pseudo: String
    let tag: String
    let niveau: Int?
    let icone: UIImage?
    let file: FileRecherche
    let classement: Classement?

    var winRate: Int? {
        guard let classement else { return nil }
        let total = classement.wins + classement.losses
        return total == 0 ? 0 : Int(Double(classement.wins) / Double(total) * 100)
    }

    // Exemple utilisé dans la galerie des widgets et pour les aperçus
    static let exemple = ResumeCompte(
        pseudo: "BbokAri",
        tag: "lee",
        niveau: 412,
        icone: nil,
        file: .soloQ,
        classement: Classement(
            queueType: "RANKED_SOLO_5x5",
            tier: "EMERALD",
            rank: "II",
            leaguePoints: 64,
            wins: 58,
            losses: 49
        )
    )
}

struct FournisseurCompte: AppIntentTimelineProvider {
    // Rafraîchissement toutes les 30 min : assez pour suivre les LP,
    // sans épuiser la limite de requêtes de la clé Riot.
    private let intervalleRafraichissement: TimeInterval = 30 * 60

    func placeholder(in context: Context) -> EntreeCompte {
        EntreeCompte(date: .now, etat: .donnees(.exemple))
    }

    func snapshot(for configuration: ConfigurationCompteIntent, in context: Context) async -> EntreeCompte {
        // Dans la galerie de widgets on montre un exemple plutôt que d'attendre l'API
        if context.isPreview {
            return EntreeCompte(date: .now, etat: .donnees(.exemple))
        }
        return await chargerEntree(configuration)
    }

    func timeline(for configuration: ConfigurationCompteIntent, in context: Context) async -> Timeline<EntreeCompte> {
        let entree = await chargerEntree(configuration)
        let prochaineMaj = Date.now.addingTimeInterval(intervalleRafraichissement)
        return Timeline(entries: [entree], policy: .after(prochaineMaj))
    }

    // Découpe le Riot ID, appelle l'API puis télécharge l'icône de profil
    private func chargerEntree(_ configuration: ConfigurationCompteIntent) async -> EntreeCompte {
        let morceaux = configuration.riotID.split(separator: "#")

        guard morceaux.count == 2 else {
            return EntreeCompte(date: .now, etat: .aConfigurer)
        }

        let pseudo = String(morceaux[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let tag = String(morceaux[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        let file = configuration.file.fileRecherche

        do {
            let resultat = try await APIRiot().rechercherResumeCompte(pseudo: pseudo, tag: tag, file: file)

            // AsyncImage ne marche pas dans un widget : l'image doit être téléchargée ici
            var icone: UIImage?
            if let url = resultat.urlIcone,
               let (donnees, _) = try? await URLSession.shared.data(from: url) {
                icone = UIImage(data: donnees)
            }

            let resume = ResumeCompte(
                pseudo: resultat.compte.gameName,
                tag: resultat.compte.tagLine,
                niveau: resultat.invocateur?.summonerLevel,
                icone: icone,
                file: file,
                classement: resultat.classement
            )
            return EntreeCompte(date: .now, etat: .donnees(resume))
        } catch {
            return EntreeCompte(date: .now, etat: .erreur(error.localizedDescription))
        }
    }
}
