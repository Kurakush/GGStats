//
//  APIRiot.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

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
                return "Erreur 404 : joueur introuvable ou mauvais serveur LoL."
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

    func rechercherJoueur(pseudo: String, tag: String) async throws -> (CompteRiot, Invocateur, Classement?) {
        let compte = try await recupererCompte(pseudo: pseudo, tag: tag)

        let invocateur = try await recupererInvocateur(puuid: compte.puuid)

        let classements = try await recupererClassements(puuid: compte.puuid)

        let classementSoloQ = classements.first { classement in
            classement.queueType == "RANKED_SOLO_5x5"
        }

        return (compte, invocateur, classementSoloQ)
    }

    private func recupererCompte(pseudo: String, tag: String) async throws -> CompteRiot {
        let pseudoEncode = pseudo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pseudo
        let tagEncode = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag

        let adresse = "https://\(regionCompte).api.riotgames.com/riot/account/v1/accounts/by-riot-id/\(pseudoEncode)/\(tagEncode)"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        return try await envoyerRequete(url)
    }

    private func recupererInvocateur(puuid: String) async throws -> Invocateur {
        let adresse = "https://\(regionLol).api.riotgames.com/lol/summoner/v4/summoners/by-puuid/\(puuid)"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        return try await envoyerRequete(url)
    }

    private func recupererClassements(puuid: String) async throws -> [Classement] {
        let adresse = "https://\(regionLol).api.riotgames.com/lol/league/v4/entries/by-puuid/\(puuid)"

        guard let url = URL(string: adresse) else {
            throw ErreurAPIRiot.mauvaiseURL
        }

        return try await envoyerRequete(url)
    }

    private func envoyerRequete<T: Decodable>(_ url: URL) async throws -> T {
        var requete = URLRequest(url: url)
        requete.setValue(cleAPI, forHTTPHeaderField: "X-Riot-Token")

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
}
