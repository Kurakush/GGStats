//
//  RechercheView.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI

struct RechercheView: View {
    @ObservedObject var vueModele: JoueurVueModele

    @State private var riotID = ""
    @State private var fileChoisie: FileRecherche = .soloQ
    @State private var allerVersResultat = false
    @State private var erreurSaisie = ""

    var body: some View {
        ZStack {
            FondDegradeGG()

            VStack(spacing: 26) {
                VStack(spacing: 8) {
                    Text("Recherche")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.white)

                    Text("Entre un Riot ID comme Faker#KR1")
                        .foregroundStyle(.white.opacity(0.75))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Riot ID")
                        .font(.headline)
                        .foregroundStyle(.white)

                    TextField("Pseudo#TAG", text: $riotID)
                        .padding()
                        .background(.white)
                        .cornerRadius(14)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("File")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Picker("File", selection: $fileChoisie) {
                        ForEach(FileRecherche.allCases) { file in
                            Text(file.rawValue).tag(file)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button {
                    Task {
                        await rechercherJoueur()
                    }
                } label: {
                    Text(vueModele.chargement ? "Recherche..." : "Rechercher")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.ggBleu, .ggViolet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(radius: 8)
                }
                .disabled(vueModele.chargement)

                if vueModele.chargement {
                    ProgressView()
                        .tint(.white)
                }

                if !erreurSaisie.isEmpty {
                    Text(erreurSaisie)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.red.opacity(0.35))
                        .cornerRadius(12)
                }

                if !vueModele.messageErreur.isEmpty {
                    Text(vueModele.messageErreur)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.35))
                        .cornerRadius(12)
                }

                NavigationLink(
                    "",
                    destination: ResultatView(vueModele: vueModele),
                    isActive: $allerVersResultat
                )
                .hidden()

                Spacer()
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    func rechercherJoueur() async {
        erreurSaisie = ""

        let parties = riotID.split(separator: "#")

        if parties.count != 2 {
            erreurSaisie = "Entre le pseudo au format : Pseudo#TAG"
            return
        }

        let pseudo = String(parties[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let tag = String(parties[1]).trimmingCharacters(in: .whitespacesAndNewlines)

        if pseudo.isEmpty || tag.isEmpty {
            erreurSaisie = "Le pseudo ou le tag est vide."
            return
        }

        await vueModele.rechercher(
            pseudo: pseudo,
            tag: tag,
            file: fileChoisie
        )

        if vueModele.compte != nil {
            allerVersResultat = true
        }
    }
}
