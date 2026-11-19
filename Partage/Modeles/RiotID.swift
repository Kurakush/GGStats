//
//  RiotID.swift
//  GGStats
//
//  Découpage d'un Riot ID "Pseudo#TAG".
//  Utilisé par la recherche iPhone, la recherche montre et le widget.
//

import Foundation

enum ErreurRiotID: LocalizedError, Equatable {
    case formatInvalide
    case champVide

    var errorDescription: String? {
        switch self {
        case .formatInvalide:
            return "Entre le pseudo au format : Pseudo#TAG"
        case .champVide:
            return "Le pseudo ou le tag est vide."
        }
    }
}

struct RiotID: Equatable {
    let pseudo: String
    let tag: String

    // Vérifie qu'il y a exactement un "#", puis que le pseudo et le tag ne sont pas vides.
    // Les espaces autour sont retirés, ceux à l'intérieur du pseudo sont gardés ("Le Bon Joueur#EUW").
    static func analyser(_ texte: String) throws -> RiotID {
        // omittingEmptySubsequences: false pour que "Pseudo#" ou "Pseudo##TAG" soient bien détectés
        let morceaux = texte.split(separator: "#", omittingEmptySubsequences: false)

        guard morceaux.count == 2 else {
            throw ErreurRiotID.formatInvalide
        }

        let pseudo = morceaux[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let tag = morceaux[1].trimmingCharacters(in: .whitespacesAndNewlines)

        guard !pseudo.isEmpty, !tag.isEmpty else {
            throw ErreurRiotID.champVide
        }

        return RiotID(pseudo: pseudo, tag: tag)
    }
}
