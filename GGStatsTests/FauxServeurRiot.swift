//
//  FauxServeurRiot.swift
//  GGStatsTests
//
//  Faux serveur Riot / Data Dragon pour les tests.
//  Il intercepte les requêtes de l'URLSession passée à APIRiot et renvoie des réponses
//  préparées à l'avance : les tests ne dépendent ni d'Internet ni de la clé API (qui expire).
//

import Foundation
import Testing

// Tous les tests qui utilisent le faux serveur sont rangés dans cette suite.
// .serialized : ils s'exécutent l'un après l'autre car le faux serveur est partagé.
@Suite("Tests avec faux serveur Riot", .serialized)
struct TestsAvecFauxServeur {}

// MARK: - Interception des requêtes

final class ProtocoleFaux: URLProtocol {
    private static let verrou = NSLock()
    nonisolated(unsafe) private static var routes: [String: (statut: Int, donnees: Data)] = [:]
    nonisolated(unsafe) private static var requetesRecues: [URLRequest] = []

    static func reinitialiser() {
        verrou.withLock {
            routes = [:]
            requetesRecues = []
        }
    }

    static func ajouterRoute(_ chemin: String, statut: Int, donnees: Data) {
        verrou.withLock { routes[chemin] = (statut, donnees) }
    }

    static var requetes: [URLRequest] {
        verrou.withLock { requetesRecues }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        // On cherche la réponse par le chemin de l'URL (sans les paramètres ?queue=...)
        let reponse = Self.verrou.withLock { () -> (statut: Int, donnees: Data)? in
            Self.requetesRecues.append(request)
            return Self.routes[url.path]
        } ?? (404, Data("route inconnue du faux serveur : \(url.path)".utf8))

        let http = HTTPURLResponse(url: url, statusCode: reponse.statut, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reponse.donnees)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Faux serveur pré-rempli

// Un joueur "BbokAri#lee" complet : compte, profil, classements, maîtrises,
// 2 parties LoL et 8 parties TFT. Chaque test peut ensuite modifier une route.
struct FauxServeurRiot {
    static let puuid = "PUUID-1"
    static let versionDataDragon = "16.23.1"

    let session: URLSession

    init(pseudo: String = "BbokAri", tag: String = "lee") {
        ProtocoleFaux.reinitialiser()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ProtocoleFaux.self]
        session = URLSession(configuration: config)

        let p = Self.puuid
        repondre("/riot/account/v1/accounts/by-riot-id/\(pseudo)/\(tag)",
                 json: ["puuid": p, "gameName": pseudo, "tagLine": tag])
        repondre("/lol/summoner/v4/summoners/by-puuid/\(p)",
                 json: ["puuid": p, "profileIconId": 7099, "summonerLevel": 699])
        repondre("/lol/league/v4/entries/by-puuid/\(p)", json: [
            Self.classement(queue: "RANKED_FLEX_SR", tier: "GOLD", rank: "I", lp: 10, wins: 5, losses: 5),
            Self.classement(queue: "RANKED_SOLO_5x5", tier: "EMERALD", rank: "II", lp: 64, wins: 58, losses: 49)
        ])
        repondre("/lol/champion-mastery/v4/champion-masteries/by-puuid/\(p)/top", json: [
            ["championId": 103, "championLevel": 7, "championPoints": 250000],
            ["championId": 424242, "championLevel": 5, "championPoints": 1000], // champion inconnu de Data Dragon
            ["championId": 157, "championLevel": 6, "championPoints": 90000]
        ])

        // Data Dragon
        repondre("/api/versions.json", json: [Self.versionDataDragon, "16.22.1"])
        repondre("/cdn/\(Self.versionDataDragon)/data/fr_FR/champion.json", json: ["data": [
            "Ahri": ["id": "Ahri", "key": "103", "name": "Ahri"],
            "Yasuo": ["id": "Yasuo", "key": "157", "name": "Yasuo"]
        ]])

        // Historique LoL : une victoire puis une défaite
        repondre("/lol/match/v5/matches/by-puuid/\(p)/ids", json: ["EUW1_1", "EUW1_2"])
        repondre("/lol/match/v5/matches/EUW1_1", json: Self.partieLoL(id: "EUW1_1", victoire: true))
        repondre("/lol/match/v5/matches/EUW1_2", json: Self.partieLoL(id: "EUW1_2", victoire: false))

        // Historique TFT : T4 est une partie non classée (queue 1090) qui doit être ignorée
        let tft: [(id: String, queue: Int, placement: Int)] = [
            ("T1", 1100, 1), ("T2", 1100, 4), ("T3", 1100, 5), ("T4", 1090, 2),
            ("T5", 1100, 8), ("T6", 1100, 2), ("T7", 1100, 3), ("T8", 1100, 6)
        ]
        repondre("/tft/match/v1/matches/by-puuid/\(p)/ids", json: tft.map(\.id))
        for partie in tft {
            repondre("/tft/match/v1/matches/\(partie.id)",
                     json: Self.partieTFT(id: partie.id, queue: partie.queue, placement: partie.placement))
        }
    }

    func repondre(_ chemin: String, statut: Int = 200, json: Any) {
        let donnees = try! JSONSerialization.data(withJSONObject: json)
        ProtocoleFaux.ajouterRoute(chemin, statut: statut, donnees: donnees)
    }

    func erreur(_ chemin: String, statut: Int) {
        ProtocoleFaux.ajouterRoute(chemin, statut: statut, donnees: Data("{\"status\":{\"status_code\":\(statut)}}".utf8))
    }

    var requetes: [URLRequest] { ProtocoleFaux.requetes }
    var cheminsAppeles: [String] { requetes.compactMap { $0.url?.path } }

    // MARK: Données de test

    static func classement(queue: String, tier: String, rank: String, lp: Int, wins: Int, losses: Int) -> [String: Any] {
        ["queueType": queue, "tier": tier, "rank": rank, "leaguePoints": lp, "wins": wins, "losses": losses]
    }

    // Partie de 30 min 5 s. Notre joueur joue Ahri en équipe bleue : 10/2/5 avec 180 + 30 CS.
    static func partieLoL(id: String, victoire: Bool) -> [String: Any] {
        var participants: [[String: Any]] = [[
            "puuid": puuid, "championName": "Ahri", "kills": 10, "deaths": 2, "assists": 5,
            "win": victoire, "teamId": 100, "totalMinionsKilled": 180, "neutralMinionsKilled": 30,
            "riotIdGameName": "BbokAri", "riotIdTagline": "lee"
        ]]
        for i in 1..<10 {
            let equipe = i < 5 ? 100 : 200
            var joueur: [String: Any] = [
                "puuid": "AUTRE-\(i)", "championName": "Champion\(i)", "kills": i, "deaths": 1, "assists": 0,
                "win": equipe == 100 ? victoire : !victoire, "teamId": equipe
            ]
            // Le joueur 9 n'a pas de pseudo : l'app doit afficher "Joueur"
            if i != 9 { joueur["riotIdGameName"] = "Joueur\(i)" }
            participants.append(joueur)
        }
        return [
            "metadata": ["matchId": id],
            "info": ["gameCreation": 1_700_000_000_000, "gameDuration": 1805, "participants": participants]
        ]
    }

    static func partieTFT(id: String, queue: Int, placement: Int) -> [String: Any] {
        [
            "metadata": ["match_id": id],
            "info": [
                "game_datetime": 1_700_000_000_000,
                "queue_id": queue,
                "participants": [
                    ["puuid": puuid, "placement": placement, "level": 9, "players_eliminated": 2],
                    ["puuid": "AUTRE", "placement": placement == 1 ? 2 : 1, "level": 8]
                ]
            ]
        ]
    }
}
