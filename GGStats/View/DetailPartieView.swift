//
//  DetailPartieView.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI

struct DetailPartieView: View {
    let partie: HistoriquePartie

    var equipeBleue: [ChampionPartie] {
        partie.championsPartie.filter { $0.teamId == 100 }
    }

    var equipeRouge: [ChampionPartie] {
        partie.championsPartie.filter { $0.teamId == 200 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(partie.resultat)
                    .font(.largeTitle)
                    .bold(true)
                    .foregroundStyle(partie.positif ? .green : .red)

                Text(partie.date)
                    .foregroundStyle(.secondary)

                equipeView(titre: "Équipe bleue", joueurs: equipeBleue)
                equipeView(titre: "Équipe rouge", joueurs: equipeRouge)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Détail de la game")
    }

    func equipeView(titre: String, joueurs: [ChampionPartie]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titre)
                .font(.title2)
                .bold(true)

            ForEach(joueurs) { joueur in
                HStack(spacing: 14) {
                    AsyncImage(
                        url: URL(string: "https://ddragon.leagueoflegends.com/cdn/15.12.1/img/champion/\(joueur.champion).png")
                    ) { image in
                        image
                            .resizable()
                            .frame(width: 46, height: 46)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                            .frame(width: 46, height: 46)
                    }

                    VStack(alignment: .leading) {
                        Text(joueur.champion)
                            .font(.headline)

                        Text(joueur.pseudo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(joueur.kills)/\(joueur.deaths)/\(joueur.assists)")
                        .font(.headline)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
        }
    }
}
