//
//  AProposView.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI

struct AProposView: View {
    var body: some View {
        ZStack {
            FondDegradeGG()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Text("À propos")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(.white)

                        Text("GGStats")
                            .font(.title2)
                            .bold(true)
                            .foregroundStyle(Color.ggVioletClair)

                        Text("Une application SwiftUI pour consulter les statistiques d’un joueur League of Legends.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)

                    carteInfo(
                        titre: "Objectif du projet",
                        icone: "target",
                        texte: "L’application permet de rechercher un joueur avec son Riot ID, puis d’afficher son profil, son rang, son win rate, ses maîtrises de champions et ses dernières parties."
                    )

                    carteInfo(
                        titre: "Fonctionnalités",
                        icone: "gamecontroller.fill",
                        texte: "Recherche par pseudo#tag, choix de la file SoloQ, Flex ou TFT, affichage des 5 dernières games, des champions joués et des détails de chaque partie."
                    )

                    carteTechnologies

                    carteInfo(
                        titre: "API utilisée",
                        icone: "network",
                        texte: "GGStats utilise l’API Riot Games pour récupérer les données du compte, le classement, les maîtrises de champions et l’historique des matchs."
                    )

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }

    var carteTechnologies: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(Color.ggVioletClair)

                Text("Technologies utilisées")
                    .font(.title2)
                    .bold(true)
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                ligneTech(nom: "SwiftUI", description: "Interface graphique")
                ligneTech(nom: "URLSession", description: "Requêtes HTTP")
                ligneTech(nom: "Codable", description: "Décodage JSON")
                ligneTech(nom: "Riot API", description: "Données League of Legends")
                ligneTech(nom: "Data Dragon", description: "Images des champions")
            }
        }
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8)
    }

    func carteInfo(titre: String, icone: String, texte: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icone)
                    .foregroundStyle(Color.ggVioletClair)

                Text(titre)
                    .font(.title2)
                    .bold(true)
                    .foregroundStyle(.white)
            }

            Text(texte)
                .foregroundStyle(.white.opacity(0.80))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8)
    }

    func ligneTech(nom: String, description: String) -> some View {
        HStack {
            Text(nom)
                .bold(true)
                .foregroundStyle(.white)

            Spacer()

            Text(description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.70))
        }
        .padding()
        .background(Color.white.opacity(0.10))
        .cornerRadius(14)
    }
}
