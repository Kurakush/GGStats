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
        ZStack {
            FondDegradeGG()

            ScrollView {
                VStack(spacing: 20) {
                    carteProfil

                    if !vueModele.maitrises.isEmpty {
                        carteMaitrises
                    }

                    if vueModele.fileChoisie != .tft {
                        carteClassement
                    }

                    carteStatsDernieresParties

                    historiqueParties
                }
                .padding()
            }
            .background(Color.clear)
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
    }

    var carteProfil: some View {
        VStack(spacing: 14) {
            if let invocateur = vueModele.invocateur {
                AsyncImage(
                    url: URL(string: "https://ddragon.leagueoflegends.com/cdn/15.12.1/img/profileicon/\(invocateur.profileIconId).png")
                ) { image in
                    image
                        .resizable()
                        .frame(width: 115, height: 115)
                        .clipShape(Circle())
                        .shadow(color: Color.ggVioletClair.opacity(0.8), radius: 12)
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 115, height: 115)
                }
            }

            if let compte = vueModele.compte {
                Text("\(compte.gameName)#\(compte.tagLine)")
                    .font(.title)
                    .bold(true)
                    .foregroundColor(.white)
            }

            if let invocateur = vueModele.invocateur {
                Text("Niveau \(invocateur.summonerLevel)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.75))
            }

            Text(vueModele.fileChoisie.titre)
                .font(.subheadline)
                .bold(true)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.ggVioletClair.opacity(0.30))
                .foregroundColor(.white)
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8)
    }

    var carteMaitrises: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top 3 maîtrises")
                .font(.title2)
                .bold(true)
                .foregroundColor(.white)

            HStack(spacing: 12) {
                ForEach(vueModele.maitrises) { maitrise in
                    VStack(spacing: 8) {
                        AsyncImage(
                            url: URL(string: "https://ddragon.leagueoflegends.com/cdn/15.12.1/img/champion/\(maitrise.cleImage).png")
                        ) { image in
                            image
                                .resizable()
                                .frame(width: 62, height: 62)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } placeholder: {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 62, height: 62)
                        }

                        Text(maitrise.nom)
                            .font(.caption)
                            .bold(true)
                            .lineLimit(1)
                            .foregroundColor(.white)

                        Text("M\(maitrise.niveau)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.75))

                        Text("\(maitrise.points) pts")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.white.opacity(0.10))
                    .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8)
    }

    var carteClassement: some View {
        VStack(spacing: 12) {
            Text("Classement")
                .font(.title2)
                .bold(true)
                .foregroundColor(.white)

            if let classement = vueModele.classement {
                let totalParties = classement.wins + classement.losses
                let winRate = calculerPourcentage(valeur: classement.wins, total: totalParties)

                Text("\(classement.tier) \(classement.rank)")
                    .font(.title3)
                    .bold(true)
                    .foregroundColor(.white)

                Text("\(classement.leaguePoints) LP")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.85))

                HStack {
                    statBloc(nombre: "\(classement.wins)", titre: "Victoires")

                    Spacer()

                    statBloc(nombre: "\(classement.losses)", titre: "Défaites")

                    Spacer()

                    statBloc(nombre: "\(winRate)%", titre: "Win rate")
                }
                .padding(.horizontal)

                ProgressView(value: Double(classement.wins), total: Double(totalParties))
                    .tint(Color.ggVioletClair)
                    .padding(.horizontal)
            } else {
                Text("Pas classé dans cette file.")
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8)
    }

    var carteStatsDernieresParties: some View {
        VStack(spacing: 12) {
            Text("Statistiques récentes")
                .font(.title2)
                .bold(true)
                .foregroundColor(.white)

            if vueModele.parties.isEmpty {
                Text("Aucune partie récente trouvée.")
                    .foregroundColor(.white.opacity(0.75))
            } else {
                let partiesPositives = vueModele.parties.filter { $0.positif }.count
                let total = vueModele.parties.count
                let pourcentage = calculerPourcentage(valeur: partiesPositives, total: total)

                Text("\(pourcentage)%")
                    .font(.largeTitle)
                    .bold(true)
                    .foregroundColor(pourcentage >= 50 ? .green : .red)

                Text(vueModele.fileChoisie == .tft ? "Top 4 rate sur les \(total) dernières parties" : "Win rate sur les \(total) dernières parties")
                    .foregroundColor(.white.opacity(0.75))

                ProgressView(value: Double(partiesPositives), total: Double(total))
                    .tint(Color.ggVioletClair)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8)
    }

    var historiqueParties: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("5 dernières parties")
                .font(.title2)
                .bold(true)
                .foregroundColor(.white)

            if vueModele.parties.isEmpty {
                Text("Aucune partie trouvée pour cette file.")
                    .foregroundColor(.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ggCarte)
                    .cornerRadius(18)
            } else {
                ForEach(vueModele.parties) { partie in
                    if partie.championsPartie.isEmpty {
                        cartePartie(partie)
                    } else {
                        NavigationLink {
                            DetailPartieView(partie: partie)
                        } label: {
                            cartePartie(partie)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    func cartePartie(_ partie: HistoriquePartie) -> some View {
        HStack(spacing: 14) {
            if let championIcone = partie.championIcone {
                AsyncImage(
                    url: URL(string: "https://ddragon.leagueoflegends.com/cdn/15.12.1/img/champion/\(championIcone).png")
                ) { image in
                    image
                        .resizable()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 52, height: 52)
                }
            } else {
                Text(partie.positif ? "✓" : "×")
                    .font(.title)
                    .bold(true)
                    .foregroundColor(partie.positif ? .green : .red)
                    .frame(width: 52, height: 52)
                    .background(partie.positif ? Color.green.opacity(0.20) : Color.red.opacity(0.20))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(partie.titre)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(partie.sousTitre)
                    .foregroundColor(.white.opacity(0.75))

                Text(partie.details)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(partie.resultat)
                    .font(.headline)
                    .foregroundColor(partie.positif ? .green : .red)

                Text(partie.date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))

                if !partie.championsPartie.isEmpty {
                    Text("Voir game")
                        .font(.caption)
                        .foregroundColor(Color.ggVioletClair)
                }
            }
        }
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.20), radius: 5)
    }

    func statBloc(nombre: String, titre: String) -> some View {
        VStack {
            Text(nombre)
                .font(.title3)
                .bold(true)
                .foregroundColor(.white)

            Text(titre)
                .font(.caption)
                .foregroundColor(.white.opacity(0.70))
        }
    }

    func calculerPourcentage(valeur: Int, total: Int) -> Int {
        if total == 0 {
            return 0
        }

        return Int((Double(valeur) / Double(total)) * 100)
    }
}
