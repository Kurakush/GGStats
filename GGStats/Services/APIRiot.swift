//
//  APIRiot.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import Foundation

class APIRiot {
    
    private let cleAPI = "RGAPI-81547bf7-cfc5-4551-8ccf-912189a759e5"
    
    private let regionCompte = "europe"
    private let regionLoL = "euw1"
    
    func rechercherJoueur(pseudo: String, tag: String) async throws -> (CompteRiot, Invocateur, Classement?) {
        let compte = try await recupererCompte(pseudo: pseudo, tag: tag)
        let invocateur = try await recupererInvocateur(puuid: compte.puuid)
        let classements = try await recupererClassements(idInvocateur: invocateur.puuid)
        
        let classementSoloQ = classements.first { classement in classement.queueType == "RANKED_SOLO_5x5"}
        
        return (compte, invocateur, classementSoloQ)
    }
    
    private func recupererCompte(pseudo: String, tag: String) async throws -> CompteRiot {
        let pseudoEncode = pseudo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pseudo
        let tagEncode = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
        
        let adresse = "https://\(regionCompte).api.riotgames.com/riot/account/v1/account/by-riot-id/\(pseudoEncode)/\(tagEncode)"
        
        guard let url = URL(string: adresse) else {
            throw URLError(.badURL)
        }
        
        return try await envoyerRequete(url)
    }
    
    
}
