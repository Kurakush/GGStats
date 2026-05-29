//
//  JoueurVueModele.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import Foundation
import Combine

class JoueurVueModele: ObservableObject {
    @Published var compte: CompteRiot?
    @Published var invocateur: Invocateur?
    @Published var classement: Classement?
    
    @Published var chargement = false
    @Published var messageErreur = ""
    
    private let api = APIRiot()
    
    func rechercher(pseudo: String, tag: String) async {
        await MainActor.run {
            chargement = true
            messageErreur = ""
            compte = nil
            invocateur = nil
            classement = nil
        }
        
        do {
            let resultat = try await api.rechercherJoueur(pseudo: pseudo, tag: tag)
            
            await MainActor.run {
                compte = resultat.0
                invocateur = resultat.1
                classement = resultat.2
                chargement = false
            }
            
        } catch {
            await MainActor.run {
                messageErreur = error.localizedDescription
                chargement = false
            }
        }
    }
}
