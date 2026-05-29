//
//  AccueilView.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI

struct AccueilView: View {
    @StateObject var viewModel = JoueurVueModele()

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
                }
                .padding()
            }
        }
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
