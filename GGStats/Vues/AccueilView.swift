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
            VStack (spacing: 30) {
                Spacer()
                Text("Bienvenue sur GGStats")
                    .font(.largeTitle)
                    .bold(true)
                
                Text("Recherche un joueur League of Legends et affiche son niveau, son icône et son rang soloQ.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                NavigationLink("Commencer"){
                    RechercheView(vueModele: viewModel)
                 }
                 .buttonStyle(.borderedProminent)
                
                NavigationLink("A propos") {
                  AProposView()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Accueil")
        }
    }
}
