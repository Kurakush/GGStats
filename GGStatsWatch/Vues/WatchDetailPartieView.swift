//
//  WatchDetailPartieView.swift
//  GGStatsWatch
//
//  Détail d'une partie LoL : les 10 joueurs répartis en équipe bleue / rouge.
//

import SwiftUI

struct WatchDetailPartieView: View {
    let partie: HistoriquePartie

    var body: some View {
        List {
            Section {
                VStack(spacing: 2) {
                    Text(partie.resultat)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(partie.positif ? .green : .red)

                    Text(partie.date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(partie.details)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            sectionEquipe(titre: "Équipe bleue", couleur: .blue, teamId: 100)
            sectionEquipe(titre: "Équipe rouge", couleur: .red, teamId: 200)
        }
        .navigationTitle(partie.titre)
        .containerBackground(Color.ggVioletFonce.gradient, for: .navigation)
    }

    private func sectionEquipe(titre: String, couleur: Color, teamId: Int) -> some View {
        Section {
            ForEach(partie.championsPartie.filter { $0.teamId == teamId }) { joueur in
                HStack(spacing: 8) {
                    WatchImageDistante(url: URLsDataDragon.champion(joueur.champion), taille: 26)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(joueur.pseudo)
                            .font(.caption2)
                            .lineLimit(1)

                        Text("\(joueur.kills)/\(joueur.deaths)/\(joueur.assists)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text(titre)
                .foregroundStyle(couleur)
        }
    }
}
