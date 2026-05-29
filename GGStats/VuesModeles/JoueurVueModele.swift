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
    @Published var parties: [HistoriquePartie] = []
    @Published var maitrises: [MaitriseChampion] = []

    @Published var fileChoisie: FileRecherche = .soloQ

    @Published var chargement = false
    @Published var messageErreur = ""

    private let api = APIRiot()

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
