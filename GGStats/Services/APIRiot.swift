//
//  APIRiot.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//
//RGAPI-81547bf7-cfc5-4551-8ccf-912189a759e5"

import Foundation

enum ErreurAPIRiot: LocalizedError {
    case mauvaiseURL
    case erreurHTTP(Int, String)

    var errorDescription: String? {
        switch self {
        case .mauvaiseURL:
            return "URL invalide."

        case .erreurHTTP(let code, let message):
            if code == 403 {
                return "Erreur 403 : clé API invalide ou expirée."
            } else if code == 404 {
                return "Erreur 404 : joueur introuvable ou mauvais serveur."
            } else if code == 429 {
                return "Erreur 429 : trop de requêtes envoyées."
            } else {
                return "Erreur HTTP \(code) : \(message)"
            }
        }
    }
}

class APIRiot {
    private let cleAPI = "RGAPI-81547bf7-cfc5-4551-8ccf-912189a759e5"

    private let regionCompte = "europe"
    private let regionLol = "euw1"
    private let regionMatch = "europe"

    func rechercherJoueur(
        pseudo: String,
        tag: String,
        file: FileRecherche
    ) async throws -> (
        compte: CompteRiot,
        invocateur: Invocateur?,
        classement: Classement?,
        parties: [HistoriquePartie],
        maitrises: [MaitriseChampion]
    ) {
        let compte = try await recupererCompte(pseudo: pseudo, tag: tag)
        let invocateur = try? await recupererInvocateur(puuid: compte.puuid)
        let maitrises = try await recupererTopMaitrises(puuid: compte.puuid)

        if file == .tft {
            let parties = try await recupererHistoriqueTFT(puuid: compte.puuid)

            return (
                compte: compte,
                invocateur: invocateur,
                classement: nil,
                parties: parties,
                maitrises: maitrises
            )
        } else {
            let classements = try await recupererClassements(puuid: compte.puuid)

            let classementFile = classements.first { classement in
                classement.queueType == file.queueTypeClassement
            }

            let parties = try await recupererHistoriqueLoL(
                puuid: compte.puuid,
                file: file
            )

            return (
                compte: compte,
                invocateur: invocateur,
                classement: classementFile,
                parties: parties,
                maitrises: maitrises
            )
        }
    }

    private func recupererCompte(pseudo: String, tag: String) async throws -> CompteRiot {
        let pseudoEncode = pseudo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pseudo
        let tagEncode = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag

        let adresse = "https://\(regionCompte).api.riotgames.com/riot/account/v1/accounts/by-riot-id/\(pseudoEncode)/\(tagEncode)"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        return try await envoyerRequete(url, avecToken: true)
    }

    private func recupererInvocateur(puuid: String) async throws -> Invocateur {
        let adresse = "https://\(regionLol).api.riotgames.com/lol/summoner/v4/summoners/by-puuid/\(puuid)"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        return try await envoyerRequete(url, avecToken: true)
    }

    private func recupererClassements(puuid: String) async throws -> [Classement] {
        let adresse = "https://\(regionLol).api.riotgames.com/lol/league/v4/entries/by-puuid/\(puuid)"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        return try await envoyerRequete(url, avecToken: true)
    }

    private func recupererTopMaitrises(puuid: String) async throws -> [MaitriseChampion] {
        let dictionnaireChampions = try await recupererDictionnaireChampions()

        let adresse = "https://\(regionLol).api.riotgames.com/lol/champion-mastery/v4/champion-masteries/by-puuid/\(puuid)/top?count=3"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        let maitrisesAPI: [MaitriseChampionAPI] = try await envoyerRequete(url, avecToken: true)

        return maitrisesAPI.compactMap { maitrise in
            guard let champion = dictionnaireChampions[maitrise.championId] else {
                return nil
            }

            return MaitriseChampion(
                id: maitrise.championId,
                nom: champion.nom,
                cleImage: champion.cleImage,
                niveau: maitrise.championLevel,
                points: maitrise.championPoints
            )
        }
    }

    private func recupererHistoriqueLoL(
        puuid: String,
        file: FileRecherche
    ) async throws -> [HistoriquePartie] {
        guard let queueId = file.queueIdLoL else {
            return []
        }

        let adresse = "https://\(regionMatch).api.riotgames.com/lol/match/v5/matches/by-puuid/\(puuid)/ids?queue=\(queueId)&start=0&count=5"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        let ids: [String] = try await envoyerRequete(url, avecToken: true)

        var parties: [HistoriquePartie] = []

        for id in ids {
            let adresseMatch = "https://\(regionMatch).api.riotgames.com/lol/match/v5/matches/\(id)"

            guard let urlMatch = URL(string: adresseMatch) else {
                continue
            }

            let match: MatchLoL = try await envoyerRequete(urlMatch, avecToken: true)

            guard let participant = match.info.participants.first(where: { $0.puuid == puuid }) else {
                continue
            }

            let championsPartie = match.info.participants.map { joueur in
                let nomJoueur = joueur.riotIdGameName ?? "Joueur"

                return ChampionPartie(
                    id: joueur.puuid,
                    pseudo: nomJoueur,
                    champion: joueur.championName,
                    kills: joueur.kills,
                    deaths: joueur.deaths,
                    assists: joueur.assists,
                    teamId: joueur.teamId,
                    win: joueur.win
                )
            }

            let cs = (participant.totalMinionsKilled ?? 0) + (participant.neutralMinionsKilled ?? 0)
            let duree = formaterDuree(match.info.gameDuration)
            let date = formaterDate(match.info.gameCreation)

            let partie = HistoriquePartie(
                id: id,
                titre: participant.championName,
                sousTitre: "\(participant.kills)/\(participant.deaths)/\(participant.assists) - \(cs) CS",
                resultat: participant.win ? "Victoire" : "Défaite",
                details: "Durée : \(duree)",
                date: date,
                positif: participant.win,
                championIcone: participant.championName,
                championsPartie: championsPartie
            )

            parties.append(partie)
        }

        return parties
    }

    private func recupererHistoriqueTFT(puuid: String) async throws -> [HistoriquePartie] {
        let adresse = "https://\(regionMatch).api.riotgames.com/tft/match/v1/matches/by-puuid/\(puuid)/ids?start=0&count=15"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        let ids: [String] = try await envoyerRequete(url, avecToken: true)

        var parties: [HistoriquePartie] = []

        for id in ids {
            let adresseMatch = "https://\(regionMatch).api.riotgames.com/tft/match/v1/matches/\(id)"

            guard let urlMatch = URL(string: adresseMatch) else {
                continue
            }

            let match: MatchTFT = try await envoyerRequete(urlMatch, avecToken: true)

            guard match.info.queue_id == 1100 else {
                continue
            }

            guard let participant = match.info.participants.first(where: { $0.puuid == puuid }) else {
                continue
            }

            let top = participant.placement <= 4
            let date = formaterDate(match.info.game_datetime)

            let partie = HistoriquePartie(
                id: id,
                titre: "Placement #\(participant.placement)",
                sousTitre: "Niveau \(participant.level)",
                resultat: top ? "Top 4" : "Bottom 4",
                details: "Joueurs éliminés : \(participant.players_eliminated ?? 0)",
                date: date,
                positif: top,
                championIcone: nil,
                championsPartie: []
            )

            parties.append(partie)

            if parties.count == 5 {
                break
            }
        }

        return parties
    }

    private func recupererDictionnaireChampions() async throws -> [Int: ChampionDataDragon] {
        let version = try await recupererVersionDataDragon()

        let adresse = "https://ddragon.leagueoflegends.com/cdn/\(version)/data/fr_FR/champion.json"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        let donnees: ChampionsDataDragon = try await envoyerRequete(url, avecToken: false)

        var resultat: [Int: ChampionDataDragon] = [:]

        for champion in donnees.data.values {
            if let idChampion = Int(champion.key) {
                resultat[idChampion] = ChampionDataDragon(
                    nom: champion.name,
                    cleImage: champion.id
                )
            }
        }

        return resultat
    }

    private func recupererVersionDataDragon() async throws -> String {
        let adresse = "https://ddragon.leagueoflegends.com/api/versions.json"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        let versions: [String] = try await envoyerRequete(url, avecToken: false)

        return versions.first ?? "15.12.1"
    }

    private func envoyerRequete<T: Decodable>(_ url: URL, avecToken: Bool) async throws -> T {
        var requete = URLRequest(url: url)

        if avecToken {
            requete.setValue(cleAPI, forHTTPHeaderField: "X-Riot-Token")
        }

        let (donnees, reponse) = try await URLSession.shared.data(for: requete)

        guard let reponseHTTP = reponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if reponseHTTP.statusCode != 200 {
            let message = String(data: donnees, encoding: .utf8) ?? "Aucun détail"
            throw ErreurAPIRiot.erreurHTTP(reponseHTTP.statusCode, message)
        }

        return try JSONDecoder().decode(T.self, from: donnees)
    }

    private func formaterDuree(_ secondes: Int) -> String {
        let minutes = secondes / 60
        let secondesRestantes = secondes % 60
        return "\(minutes)m \(secondesRestantes)s"
    }

    private func formaterDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}

private struct MatchLoL: Codable {
    let metadata: MetadataLoL
    let info: InfoLoL
}

private struct MetadataLoL: Codable {
    let matchId: String
}

private struct InfoLoL: Codable {
    let gameCreation: Int
    let gameDuration: Int
    let participants: [ParticipantLoL]
}

private struct ParticipantLoL: Codable {
    let puuid: String
    let championName: String
    let kills: Int
    let deaths: Int
    let assists: Int
    let win: Bool
    let teamId: Int
    let totalMinionsKilled: Int?
    let neutralMinionsKilled: Int?
    let riotIdGameName: String?
    let riotIdTagline: String?
}

private struct MatchTFT: Codable {
    let metadata: MetadataTFT
    let info: InfoTFT
}

private struct MetadataTFT: Codable {
    let match_id: String
}

private struct InfoTFT: Codable {
    let game_datetime: Int
    let queue_id: Int?
    let participants: [ParticipantTFT]
}

private struct ParticipantTFT: Codable {
    let puuid: String
    let placement: Int
    let level: Int
    let players_eliminated: Int?
}

private struct MaitriseChampionAPI: Codable {
    let championId: Int
    let championLevel: Int
    let championPoints: Int
}

private struct ChampionsDataDragon: Codable {
    let data: [String: ChampionDataDragonAPI]
}

private struct ChampionDataDragonAPI: Codable {
    let id: String
    let key: String
    let name: String
}

private struct ChampionDataDragon {
    let nom: String
    let cleImage: String
}
