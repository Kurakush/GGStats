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
    
    
    
    
}
