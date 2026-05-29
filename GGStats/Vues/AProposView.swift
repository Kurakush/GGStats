//
//  AProposView.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI

struct AProposView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("À propos")
                .font(.largeTitle)
                .bold()

            Text("GGStats est une application SwiftUI qui utilise l'API Riot Games pour afficher des informations simples sur un joueur League of Legends.")
                .multilineTextAlignment(.center)

            Text("Technologies utilisées")
                .font(.title2)
                .bold()

            Text("SwiftUI\nURLSession\nAPI Riot Games\nJSON / Codable")
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle("À propos")
    }
}
