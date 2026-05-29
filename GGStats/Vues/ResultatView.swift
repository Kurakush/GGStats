//
//  ResultatView.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI

struct ResultatView: View {
    @ObservedObject var vueModele: JoueurVueModele

    var body: some View {
        VStack(spacing: 20) {
            Text("Résultat")
                .font(.largeTitle)
                .bold()

            if let compte = vueModele.compte {
                Text("\(compte.gameName)#\(compte.tagLine)")
                    .font(.title2)
                    .bold()
            }

            if let invocateur = vueModele.invocateur {
                AsyncImage(
                    url: URL(string: "https://ddragon.leagueoflegends.com/cdn/15.12.1/img/profileicon/\(invocateur.profileIconId).png")
                ) { image in
                    image
                        .resizable()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                }

                Text("Niveau : \(invocateur.summonerLevel)")
                    .font(.title3)
            }

            if let classement = vueModele.classement {
                VStack(spacing: 10) {
                    Text("Classement SoloQ")
                        .font(.title2)
                        .bold()

                    Text("\(classement.tier) \(classement.rank)")
                        .font(.title3)

                    Text("\(classement.leaguePoints) LP")

                    Text("Victoires : \(classement.wins)")
                    Text("Défaites : \(classement.losses)")
                }
                .padding()
            } else {
                Text("Pas classé en SoloQ")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Profil")
    }
}
