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
    @State private var allerVersResultat = false
    @State private var erreurSaisie = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Recherche joueur")
                .font(.title)
                .bold(true)

            TextField("Pseudo Riot, ex : Faker#KR1", text: $riotID)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("Rechercher") {
                Task {
                    await rechercherJoueur()
                }
            }
            .buttonStyle(.borderedProminent)

            if vueModele.chargement {
                ProgressView()
            }

            if !erreurSaisie.isEmpty {
                Text(erreurSaisie)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if !vueModele.messageErreur.isEmpty {
                Text(vueModele.messageErreur)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
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
        .navigationTitle("Recherche")
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

        await vueModele.rechercher(pseudo: pseudo, tag: tag)

        if vueModele.invocateur != nil {
            allerVersResultat = true
        }
    }
}
