//
//  CollectionSkinsView.swift
//  GGStats
//
//  Espace "Ma collection" : les skins possédés, groupés par champion.
//  On ajoute des skins en parcourant le catalogue des champions.
//

import SwiftUI

struct CollectionSkinsView: View {
    @StateObject private var collection = CollectionSkinsVueModele()

    @State private var skinAgrandi: SkinChampion?

    private let colonnes = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ZStack {
            FondDegradeGG()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    carteResume

                    if collection.skins.isEmpty {
                        collectionVide
                    } else {
                        ForEach(collection.parChampion, id: \.nomChampion) { groupe in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(groupe.nomChampion)
                                    .font(.title3)
                                    .bold(true)
                                    .foregroundStyle(.white)

                                LazyVGrid(columns: colonnes, spacing: 12) {
                                    ForEach(groupe.skins) { skin in
                                        Button {
                                            skinAgrandi = skin
                                        } label: {
                                            CarteSkin(skin: skin, possede: true)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Ma collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CatalogueChampionsView(collection: collection)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Ajouter des skins")
            }
        }
        .sheet(item: $skinAgrandi) { skin in
            DetailSkinView(skin: skin, collection: collection)
        }
    }

    var carteResume: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(collection.skins.count)")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(.white)
                Text(collection.skins.count > 1 ? "skins possédés" : "skin possédé")
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(collection.parChampion.count)")
                    .font(.title)
                    .bold(true)
                    .foregroundStyle(.white)
                Text(collection.parChampion.count > 1 ? "champions" : "champion")
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8)
    }

    var collectionVide: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(Color.ggVioletClair)

            Text("Ta collection est vide")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Riot ne partage pas la liste des skins d'un compte : ajoute les tiens depuis le catalogue.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))

            NavigationLink {
                CatalogueChampionsView(collection: collection)
            } label: {
                Text("Parcourir les champions")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.ggBleu, .ggViolet], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ggCarte)
        .cornerRadius(24)
    }
}

// MARK: - Catalogue des champions

struct CatalogueChampionsView: View {
    @ObservedObject var collection: CollectionSkinsVueModele

    @State private var champions: [ChampionCatalogue] = []
    @State private var version = ""
    @State private var recherche = ""
    @State private var chargement = true
    @State private var messageErreur = ""

    private let api = APIRiot()

    var championsFiltres: [ChampionCatalogue] {
        guard !recherche.isEmpty else { return champions }
        return champions.filter { $0.nom.localizedCaseInsensitiveContains(recherche) }
    }

    var body: some View {
        ZStack {
            FondDegradeGG()

            if chargement {
                ProgressView()
                    .tint(.white)
            } else if !messageErreur.isEmpty {
                VStack(spacing: 12) {
                    Text(messageErreur)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.35))
                        .cornerRadius(12)

                    Button("Réessayer") {
                        Task { await charger() }
                    }
                    .foregroundStyle(.white)
                }
                .padding()
            } else {
                List(championsFiltres) { champion in
                    NavigationLink {
                        SkinsChampionView(champion: champion, version: version, collection: collection)
                    } label: {
                        ligneChampion(champion)
                    }
                    .listRowBackground(Color.ggCarte)
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $recherche, prompt: "Rechercher un champion")
            }
        }
        .navigationTitle("Champions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if champions.isEmpty {
                await charger()
            }
        }
    }

    func ligneChampion(_ champion: ChampionCatalogue) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: champion.urlIcone(version: version)) { image in
                image.resizable()
            } placeholder: {
                Color.white.opacity(0.1)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            Text(champion.nom)
                .foregroundStyle(.white)

            Spacer()

            let nombre = collection.nombrePossedes(champion: champion.id)
            if nombre > 0 {
                Text("\(nombre)")
                    .font(.caption)
                    .bold(true)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ggViolet)
                    .clipShape(Capsule())
            }
        }
    }

    func charger() async {
        chargement = true
        messageErreur = ""
        do {
            let resultat = try await api.recupererCatalogueChampions()
            version = resultat.version
            champions = resultat.champions
        } catch {
            messageErreur = error.localizedDescription
        }
        chargement = false
    }
}

// MARK: - Skins d'un champion

struct SkinsChampionView: View {
    let champion: ChampionCatalogue
    let version: String
    @ObservedObject var collection: CollectionSkinsVueModele

    @State private var skins: [SkinChampion] = []
    @State private var chargement = true
    @State private var messageErreur = ""

    private let api = APIRiot()
    private let colonnes = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ZStack {
            FondDegradeGG()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Touche un skin pour l'ajouter ou le retirer de ta collection.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))

                    if chargement {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 40)
                    } else if !messageErreur.isEmpty {
                        Text(messageErreur)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.red.opacity(0.35))
                            .cornerRadius(12)
                    } else {
                        LazyVGrid(columns: colonnes, spacing: 12) {
                            ForEach(skins) { skin in
                                Button {
                                    collection.basculer(skin)
                                } label: {
                                    CarteSkin(skin: skin, possede: collection.possede(skin))
                                }
                                .buttonStyle(.plain)
                                .sensoryFeedback(.selection, trigger: collection.possede(skin))
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(champion.nom)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if skins.isEmpty {
                await charger()
            }
        }
    }

    func charger() async {
        chargement = true
        messageErreur = ""
        do {
            skins = try await api.recupererSkins(champion: champion, version: version)
        } catch {
            messageErreur = error.localizedDescription
        }
        chargement = false
    }
}

// MARK: - Détail d'un skin

struct DetailSkinView: View {
    let skin: SkinChampion
    @ObservedObject var collection: CollectionSkinsVueModele

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.ggFond.ignoresSafeArea()

            VStack(spacing: 20) {
                AsyncImage(url: skin.urlSplash) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 220)
                }
                .cornerRadius(18)

                VStack(spacing: 6) {
                    Text(skin.nom)
                        .font(.title2)
                        .bold(true)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text(skin.nomChampion)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Button(role: .destructive) {
                    collection.basculer(skin)
                    dismiss()
                } label: {
                    Label("Retirer de ma collection", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.25))
                        .cornerRadius(16)
                }
                .foregroundStyle(.white)

                Spacer()
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Carte d'un skin

struct CarteSkin: View {
    let skin: SkinChampion
    let possede: Bool

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: skin.urlChargement) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Color.white.opacity(0.08)
                    ProgressView().tint(.white)
                }
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(14)
            .saturation(possede ? 1 : 0.2)
            .opacity(possede ? 1 : 0.6)
            .overlay(alignment: .topTrailing) {
                if possede {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, Color.ggViolet)
                        .padding(6)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(possede ? Color.ggVioletClair : .clear, lineWidth: 2)
            }

            Text(skin.nom)
                .font(.caption)
                .bold(true)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .top)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(possede ? .isSelected : [])
    }
}
