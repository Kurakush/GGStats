//
//  WatchResultatView.swift
//  GGStatsWatch
//
//  Profil du joueur version montre : infos condensées en liste verticale (scroll avec la Digital Crown).
//

import SwiftUI

struct WatchResultatView: View {
    @ObservedObject var vueModele: JoueurVueModele

    var body: some View {
        List {
            sectionProfil

            if vueModele.fileChoisie != .tft {
                sectionClassement
            }

            sectionStatsRecentes

            if !vueModele.maitrises.isEmpty {
                sectionMaitrises
            }

            sectionParties
        }
        .navigationTitle("Profil")
        .containerBackground(Color.ggVioletFonce.gradient, for: .navigation)
    }

    // MARK: - Profil

    private var sectionProfil: some View {
        Section {
            VStack(spacing: 6) {
                if let invocateur = vueModele.invocateur {
                    WatchImageDistante(
                        url: URLsDataDragon.iconeProfil(invocateur.profileIconId),
                        taille: 56
                    )
                }

                if let compte = vueModele.compte {
                    Text(compte.gameName)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("#\(compte.tagLine)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let invocateur = vueModele.invocateur {
                    Text("Niveau \(invocateur.summonerLevel)")
                        .font(.caption2)
                        .foregroundStyle(Color.ggVioletClair)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Classement

    private var sectionClassement: some View {
        Section(vueModele.fileChoisie.titre) {
            if let classement = vueModele.classement {
                let total = classement.wins + classement.losses

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(classement.tier) \(classement.rank)")
                        .font(.headline)

                    Text("\(classement.leaguePoints) LP")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(classement.wins)V · \(classement.losses)D · \(pourcentage(classement.wins, total))%")
                        .font(.caption2)

                    ProgressView(value: Double(classement.wins), total: Double(max(total, 1)))
                        .tint(Color.ggVioletClair)
                }
            } else {
                Text("Pas classé dans cette file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Stats récentes

    private var sectionStatsRecentes: some View {
        Section("Récent") {
            if vueModele.parties.isEmpty {
                Text("Aucune partie récente.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let positives = vueModele.parties.filter { $0.positif }.count
                let total = vueModele.parties.count
                let taux = pourcentage(positives, total)

                HStack {
                    Gauge(value: Double(positives), in: 0...Double(total)) {
                        EmptyView()
                    } currentValueLabel: {
                        Text("\(taux)%")
                            .foregroundStyle(taux >= 50 ? .green : .red)
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(Color.ggVioletClair)

                    Text(vueModele.fileChoisie == .tft
                         ? "Top 4 sur \(total) parties"
                         : "Win rate sur \(total) parties")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Maîtrises

    private var sectionMaitrises: some View {
        Section("Maîtrises") {
            ForEach(vueModele.maitrises) { maitrise in
                HStack(spacing: 8) {
                    WatchImageDistante(url: URLsDataDragon.champion(maitrise.cleImage), taille: 30)

                    VStack(alignment: .leading) {
                        Text(maitrise.nom)
                            .font(.caption)
                            .bold()
                            .lineLimit(1)

                        Text("M\(maitrise.niveau) · \(maitrise.points.formatted(.number.notation(.compactName))) pts")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Dernières parties

    private var sectionParties: some View {
        Section("Dernières parties") {
            if vueModele.parties.isEmpty {
                Text("Aucune partie trouvée.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vueModele.parties) { partie in
                    if partie.championsPartie.isEmpty {
                        WatchLignePartie(partie: partie)
                    } else {
                        NavigationLink {
                            WatchDetailPartieView(partie: partie)
                        } label: {
                            WatchLignePartie(partie: partie)
                        }
                    }
                }
            }
        }
    }

    private func pourcentage(_ valeur: Int, _ total: Int) -> Int {
        total == 0 ? 0 : Int(Double(valeur) / Double(total) * 100)
    }
}

// Une ligne compacte pour une partie : icône du champion (ou ✓/×), titre, KDA et résultat
struct WatchLignePartie: View {
    let partie: HistoriquePartie

    var body: some View {
        HStack(spacing: 8) {
            if let champion = partie.championIcone {
                WatchImageDistante(url: URLsDataDragon.champion(champion), taille: 30)
                    .overlay(Circle().stroke(partie.positif ? .green : .red, lineWidth: 2))
            } else {
                Image(systemName: partie.positif ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(partie.positif ? .green : .red)
                    .frame(width: 30, height: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(partie.titre)
                    .font(.caption)
                    .bold()
                    .lineLimit(1)

                Text(partie.sousTitre)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(partie.resultat)
                    .font(.caption2)
                    .foregroundStyle(partie.positif ? .green : .red)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WatchResultatView(vueModele: JoueurVueModele())
    }
}
