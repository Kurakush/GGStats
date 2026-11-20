//
//  ContentView.swift
//  GGStats
//
//  Point d'entrée des écrans : connexion si personne n'est connecté, sinon l'accueil.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                AccueilView(authManager: authManager)
            } else {
                AuthView(authManager: authManager)
            }
        }
        .animation(.default, value: authManager.isAuthenticated)
    }
}
