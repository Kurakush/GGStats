//
//  RiotIDTests.swift
//  GGStatsTests
//
//  Tests du découpage "Pseudo#TAG" saisi par l'utilisateur (iPhone, montre et widget).
//

import Foundation
import Testing
@testable import GGStats

@Suite("Riot ID")
@MainActor
struct RiotIDTests {

    @Test("Riot ID valide")
    func valide() throws {
        #expect(try RiotID.analyser("BbokAri#lee") == RiotID(pseudo: "BbokAri", tag: "lee"))
    }

    @Test("Les espaces autour sont retirés, ceux du pseudo sont gardés")
    func espaces() throws {
        #expect(try RiotID.analyser("  Le Bon Joueur # EUW  ") == RiotID(pseudo: "Le Bon Joueur", tag: "EUW"))
    }

    @Test("Les accents et caractères spéciaux sont acceptés")
    func caracteresSpeciaux() throws {
        #expect(try RiotID.analyser("Éloïse#ÉTÉ") == RiotID(pseudo: "Éloïse", tag: "ÉTÉ"))
    }

    @Test("Format invalide", arguments: ["", "BbokAri", "BbokAri#lee#2", "Bbok##lee"])
    func formatInvalide(texte: String) {
        #expect(throws: ErreurRiotID.formatInvalide) {
            try RiotID.analyser(texte)
        }
    }

    @Test("Pseudo ou tag vide", arguments: ["#lee", "BbokAri#", "   #lee", "BbokAri#   ", "#"])
    func champVide(texte: String) {
        #expect(throws: ErreurRiotID.champVide) {
            try RiotID.analyser(texte)
        }
    }

    @Test("Messages d'erreur affichés à l'utilisateur")
    func messages() {
        #expect(ErreurRiotID.formatInvalide.localizedDescription == "Entre le pseudo au format : Pseudo#TAG")
        #expect(ErreurRiotID.champVide.localizedDescription == "Le pseudo ou le tag est vide.")
    }
}
