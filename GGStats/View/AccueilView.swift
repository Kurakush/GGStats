//
//  AccueilView.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI

struct AccueilView: View {
    @StateObject var viewModel = JoueurVueModele()
    @ObservedObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                FondDegradeGG()

                VStack(spacing: 30) {
                    Spacer()

                    VStack(spacing: 12) {
                        Text("GGStats")
                            .font(.system(size: 52, weight: .black))
                            .foregroundStyle(.white)

                        Text("League of Legends Stats")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    VStack(spacing: 16) {
                        Text("Recherche un joueur avec son Riot ID, consulte son rang, son win rate, ses maîtrises et ses dernières games.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal)

                        HStack(spacing: 14) {
                            infoBadge(titre: "SoloQ", icone: "trophy.fill")
                            infoBadge(titre: "Flex", icone: "person.3.fill")
                            infoBadge(titre: "TFT", icone: "hexagon.fill")
                        }
                    }

                    NavigationLink {
                        RechercheView(vueModele: viewModel)
                    } label: {
                        Text("Commencer")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.ggVioletClair,.ggBleu, .ggViolet],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(18)
                            .shadow(radius: 10)
                    }
                    .padding(.horizontal, 30)

                    NavigationLink {
                        AProposView()
                    } label: {
                        Text("À propos")
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()

                    carteCompte
                }
                .padding()
            }
        }
    }

    // Compte Firebase connecté + déconnexion
    var carteCompte: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Connecté en tant que")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text(authManager.userEmail ?? "Utilisateur")
                    .font(.subheadline)
                    .bold(true)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.white)
            }

            Spacer()

            Button("Se déconnecter") {
                authManager.signOut()
            }
            .font(.subheadline)
            .bold(true)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.35))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(18)
    }

    func infoBadge(titre: String, icone: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icone)
                .font(.title2)

            Text(titre)
                .font(.caption)
                .bold(true)
        }
        .foregroundStyle(.white)
        .frame(width: 85, height: 75)
        .background(Color.ggCarte)
        .cornerRadius(18)
    }
}
