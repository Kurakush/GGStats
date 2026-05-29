//
//  ThemeGG.swift
//  GGStats
//
//  Created by Eve Lacroix on 29/05/2026.
//

import SwiftUI

extension Color {
    static let ggViolet = Color(red: 0.48, green: 0.18, blue: 1.00)
    static let ggVioletFonce = Color(red: 0.16, green: 0.05, blue: 0.35)
    static let ggVioletClair = Color(red: 0.70, green: 0.35, blue: 1.00)
    
    static let ggBleu = Color(red: 0.10, green: 0.35, blue: 1.00)
    static let ggFond = Color(red: 0.06, green: 0.03, blue: 0.14)
    static let ggCarte = Color.white.opacity(0.14)
}

struct FondDegradeGG: View {
    var body: some View {
        LinearGradient(
            colors: [
                .ggVioletClair,
                .ggViolet,
                .ggVioletFonce,
                .ggFond
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
