//
//  WatchRechercheView.swift
//  GGStatsWatch
//
//  Écran principal de la montre : saisie du Riot ID, choix de la file et lancement de la recherche.
//

import SwiftUI

struct WatchRechercheView: View {
    @StateObject private var vueModele = JoueurVueModele()

    // Le dernier Riot ID est mémorisé : taper au clavier sur une montre est pénible
    @AppStorage("dernierRiotID") private var riotID = ""
    @State private var fileChoisie: FileRecherche = .soloQ
    @State private var allerVersResultat = false
    @State private var erreurSaisie = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // TextFieldLink ouvre directement la saisie système de la montre
                    // (clavier, dictée ou Scribble selon le modèle).
                    // Un TextField avec .textContentType(.username) ouvrait l'AutoFill au lieu du clavier.
                    TextFieldLink(prompt: Text("Pseudo#TAG")) {
                        Label(riotID.isEmpty ? "Riot ID" : riotID, systemImage: "person.crop.circle")
                            .foregroundStyle(riotID.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                    } onSubmit: { texte in
                        riotID = texte.trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    Picker("File", selection: $fileChoisie) {
                        ForEach(FileRecherche.allCases) { file in
                            Text(file.rawValue).tag(file)
                        }
                    }
                } footer: {
                    Text("Exemple : BbokAri#lee")
                }

                Section {
                    Button {
                        Task {
                            await rechercherJoueur()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if vueModele.chargement {
                                ProgressView()
                            } else {
                                Label("Rechercher", systemImage: "magnifyingglass")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.ggBleu, .ggViolet], startPoint: .leading, endPoint: .trailing))
                    )
                    .disabled(vueModele.chargement)
                }

                if !erreurSaisie.isEmpty || !vueModele.messageErreur.isEmpty {
                    Section {
                        Text(erreurSaisie.isEmpty ? vueModele.messageErreur : erreurSaisie)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("GGStats")
            .navigationDestination(isPresented: $allerVersResultat) {
                WatchResultatView(vueModele: vueModele)
            }
            .containerBackground(Color.ggVioletFonce.gradient, for: .navigation)
        }
    }

    // Même logique que RechercheView sur iPhone : on découpe "Pseudo#TAG" puis on appelle le ViewModel
    private func rechercherJoueur() async {
        erreurSaisie = ""

        let id: RiotID
        do {
            id = try RiotID.analyser(riotID)
        } catch {
            erreurSaisie = error.localizedDescription
            return
        }

        await vueModele.rechercher(pseudo: id.pseudo, tag: id.tag, file: fileChoisie)

        if vueModele.compte != nil {
            allerVersResultat = true
        }
    }
}

#Preview {
    WatchRechercheView()
}
