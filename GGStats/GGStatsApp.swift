//
//  GGStatsApp.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct GGStatsApp: App {
    // Firebase est configuré une seule fois, au lancement de l'app.
    // Il lit GGStats/GoogleService-Info.plist (le nom doit être exact).
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Indispensable : Google renvoie le résultat de la connexion à l'app via cette URL
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

