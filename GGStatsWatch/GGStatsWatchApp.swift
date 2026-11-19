//
//  GGStatsWatchApp.swift
//  GGStatsWatch
//
//  Point d'entrée de l'application Apple Watch.
//  Elle réutilise le même ViewModel et la même API que l'app iPhone (dossier Partage).
//

import SwiftUI

@main
struct GGStatsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRechercheView()
        }
    }
}
