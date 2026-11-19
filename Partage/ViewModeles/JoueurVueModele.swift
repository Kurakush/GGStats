//
//  JoueurVueModele.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

// ViewModel qui sert d'intermédiaire entre l'API Riot et les View.
// Il stocke les données récupérées et met à jour l'interface automatiquement.
import Foundation
import Combine


class JoueurVueModele: ObservableObject {
    @Published var compte: CompteRiot?
    @Published var invocateur: Invocateur?
    @Published var classement: Classement?
    @Published var parties: [HistoriquePartie] = []
    @Published var maitrises: [MaitriseChampion] = []

    @Published var fileChoisie: FileRecherche = .soloQ

    @Published var chargement = false
    @Published var messageErreur = ""

    private let api: APIRiot

    // L'API peut être remplacée (utile pour les tests), sinon on utilise la vraie
    init(api: APIRiot = APIRiot()) {
        self.api = api
    }

    // Lance une recherche complete du joueur
    // Cette fonction recup le profil, le classement, les maitrises et les dernieres parties
    func rechercher(pseudo: String, tag: String, file: FileRecherche) async {
        await MainActor.run {
            chargement = true
            messageErreur = ""
            compte = nil
            invocateur = nil
            classement = nil
            parties = []
            maitrises = []
            fileChoisie = file
        }

        do {
            let resultat = try await api.rechercherJoueur(
                pseudo: pseudo,
                tag: tag,
                file: file
            )

            await MainActor.run {
                compte = resultat.compte
                invocateur = resultat.invocateur
                classement = resultat.classement
                parties = resultat.parties
                maitrises = resultat.maitrises
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
