//
//  GGStatsWidget.swift
//  GGStatsWidget
//
//  Widget iPhone affichant le rang d'un compte League of Legends.
//  Tailles : petit et moyen (écran d'accueil), rectangulaire et circulaire (écran verrouillé).
//

import WidgetKit
import SwiftUI

@main
struct GGStatsWidgetBundle: WidgetBundle {
    var body: some Widget {
        GGStatsWidget()
    }
}

struct GGStatsWidget: Widget {
    let kind = "GGStatsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationCompteIntent.self, provider: FournisseurCompte()) { entree in
            VueWidgetCompte(entree: entree)
        }
        .configurationDisplayName("Compte LoL")
        .description("Rang, LP et win rate d'un joueur.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

// MARK: - Vue principale : choisit l'affichage selon l'état et la taille

struct VueWidgetCompte: View {
    @Environment(\.widgetFamily) private var taille
    let entree: EntreeCompte

    var body: some View {
        contenu
            .containerBackground(for: .widget) {
                if taille == .systemSmall || taille == .systemMedium {
                    FondDegradeGG()
                } else {
                    AccessoryWidgetBackground()
                }
            }
    }

    @ViewBuilder
    private var contenu: some View {
        switch entree.etat {
        case .aConfigurer:
            VueMessage(icone: "person.crop.circle.badge.questionmark",
                       texte: "Appui long › Modifier le widget pour choisir un Riot ID")
        case .erreur(let message):
            VueMessage(icone: "exclamationmark.triangle", texte: message)
        case .donnees(let resume):
            switch taille {
            case .systemMedium: VueMoyenne(resume: resume)
            case .accessoryRectangular: VueRectangulaire(resume: resume)
            case .accessoryCircular: VueCirculaire(resume: resume)
            default: VuePetite(resume: resume)
            }
        }
    }
}

// MARK: - Petit widget

struct VuePetite: View {
    let resume: ResumeCompte

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                IconeProfil(image: resume.icone, taille: 32)
                VStack(alignment: .leading, spacing: 0) {
                    Text(resume.pseudo)
                        .font(.caption).bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let niveau = resume.niveau {
                        Text("Niv. \(niveau)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            Spacer(minLength: 0)

            if let classement = resume.classement {
                Text(Rang.texte(classement))
                    .font(.headline).bold()
                    .foregroundStyle(Rang.couleur(classement.tier))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(classement.leaguePoints) LP · \(resume.winRate ?? 0)% WR")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                Text("Non classé")
                    .font(.headline)
                Text(resume.file.titre)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Widget moyen

struct VueMoyenne: View {
    let resume: ResumeCompte

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                IconeProfil(image: resume.icone, taille: 64)
                if let niveau = resume.niveau {
                    Text("Niv. \(niveau)")
                        .font(.caption2).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.ggCarte, in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(resume.pseudo)#\(resume.tag)")
                    .font(.subheadline).bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(resume.file.titre)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))

                if let classement = resume.classement {
                    Text(Rang.texte(classement))
                        .font(.title3).bold()
                        .foregroundStyle(Rang.couleur(classement.tier))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("\(classement.leaguePoints) LP · \(classement.wins)V \(classement.losses)D")
                        .font(.caption)

                    BarreWinRate(pourcentage: resume.winRate ?? 0)

                    Text("\(resume.winRate ?? 0)% win rate")
                        .font(.caption2)
                } else {
                    Text("Non classé dans cette file")
                        .font(.callout)
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Écran verrouillé

struct VueRectangulaire: View {
    let resume: ResumeCompte

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(resume.pseudo)
                .font(.headline)
                .widgetAccentable()
                .lineLimit(1)
            if let classement = resume.classement {
                Text(Rang.texte(classement))
                    .lineLimit(1)
                Text("\(classement.leaguePoints) LP · \(resume.winRate ?? 0)% WR")
                    .font(.caption)
            } else {
                Text("Non classé")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VueCirculaire: View {
    let resume: ResumeCompte

    var body: some View {
        if let classement = resume.classement {
            Gauge(value: Double(resume.winRate ?? 0), in: 0...100) {
                Text("WR")
            } currentValueLabel: {
                Text(Rang.abreviation(classement))
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            Text("NC")
                .font(.headline)
        }
    }
}

// MARK: - Éléments réutilisables

struct VueMessage: View {
    let icone: String
    let texte: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icone)
                .font(.title2)
            Text(texte)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
    }
}

// Barre de progression dessinée à la main (rendu identique partout, couleurs de l'app)
struct BarreWinRate: View {
    let pourcentage: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.2))
                Capsule()
                    .fill(LinearGradient(colors: [.ggBleu, .ggVioletClair], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(min(max(pourcentage, 0), 100)) / 100)
            }
        }
        .frame(height: 6)
    }
}

struct IconeProfil: View {
    let image: UIImage?
    let taille: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: taille * 0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.ggCarte)
            }
        }
        .frame(width: taille, height: taille)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.ggVioletClair, lineWidth: 2))
    }
}

// MARK: - Aperçus Xcode

#Preview(as: .systemSmall) {
    GGStatsWidget()
} timeline: {
    EntreeCompte(date: .now, etat: .donnees(.exemple))
    EntreeCompte(date: .now, etat: .aConfigurer)
}

#Preview(as: .systemMedium) {
    GGStatsWidget()
} timeline: {
    EntreeCompte(date: .now, etat: .donnees(.exemple))
    EntreeCompte(date: .now, etat: .erreur("Erreur 403 : clé API invalide ou expirée."))
}
