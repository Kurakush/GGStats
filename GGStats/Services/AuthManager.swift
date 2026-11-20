//
//  AuthManager.swift
//  GGStats
//
//  Centralise toute la logique Firebase Authentication :
//  email / mot de passe, Google, Apple, et déconnexion.
//  Rangé dans GGStats/ (et pas Partage/) car seule l'app iPhone utilise Firebase.
//

import Foundation
import Combine
import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@MainActor
class AuthManager: ObservableObject {
    // Utilisateur Firebase connecté, ou nil
    @Published var user: User?
    // true si un utilisateur est connecté
    @Published var isAuthenticated = false
    // Dernier message d'erreur à afficher à l'écran
    @Published var errorMessage = ""
    // true pendant un appel réseau (pour désactiver les boutons)
    @Published var isLoading = false

    // Email de l'utilisateur connecté (les vues n'ont pas besoin d'importer Firebase)
    var userEmail: String? {
        user?.email
    }

    private var ecouteur: AuthStateDidChangeListenerHandle?

    // Nonce "en clair" de la demande Apple en cours (Apple ne reçoit que son empreinte SHA-256)
    private var nonceApple: String?

    init() {
        // Firebase garde la session entre deux lancements : on reprend l'utilisateur déjà connecté
        user = Auth.auth().currentUser
        isAuthenticated = user != nil

        // Prévenu à chaque connexion / déconnexion, même si elle vient d'ailleurs (session expirée…)
        ecouteur = Auth.auth().addStateDidChangeListener { [weak self] _, utilisateur in
            Task { @MainActor in
                self?.user = utilisateur
                self?.isAuthenticated = utilisateur != nil
            }
        }
    }

    deinit {
        if let ecouteur {
            Auth.auth().removeStateDidChangeListener(ecouteur)
        }
    }

    // Crée un compte avec email + mot de passe (l'utilisateur est connecté directement)
    func signUp(email: String, password: String) async {
        await executer {
            let resultat = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = resultat.user
        }
    }

    // Connecte un compte existant
    func signIn(email: String, password: String) async {
        await executer {
            let resultat = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = resultat.user
        }
    }

    // Connexion avec un compte Google :
    // 1. Google affiche le choix du compte et renvoie des jetons
    // 2. on transforme ces jetons en "credential" Firebase
    // 3. Firebase connecte l'utilisateur avec ce credential
    func signInWithGoogle() async {
        // Le clientID vient de GoogleService-Info.plist (via la configuration Firebase), pas écrit en dur
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "CLIENT_ID absent : retélécharge GoogleService-Info.plist après avoir activé Google."
            return
        }

        // Google a besoin d'un écran (UIViewController) pour présenter sa fenêtre
        guard let ecran = Self.ecranAuPremierPlan() else {
            errorMessage = "Impossible d'afficher la fenêtre Google."
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        await executer {
            let resultat = try await GIDSignIn.sharedInstance.signIn(withPresenting: ecran)

            guard let idToken = resultat.user.idToken?.tokenString else {
                throw ErreurConnexion.jetonManquant("Google")
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: resultat.user.accessToken.tokenString
            )

            let connexion = try await Auth.auth().signIn(with: credential)
            self.user = connexion.user
        }
    }

    // L'écran actuellement affiché, en remontant jusqu'à celui présenté le plus haut
    private static func ecranAuPremierPlan() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        var ecran = scene?.keyWindow?.rootViewController
        while let presente = ecran?.presentedViewController {
            ecran = presente
        }
        return ecran
    }

    // MARK: - Sign in with Apple
    //
    // ⚠️ Nécessite un compte Apple Developer payant : capability "Sign in with Apple" sur la cible,
    // et fournisseur Apple configuré dans Firebase (Service ID + clé .p8).
    // Sans ça, Apple renvoie une erreur et on affiche un message explicatif.
    //
    // Le nonce protège contre le rejeu : on envoie à Apple l'empreinte SHA-256 d'une valeur aléatoire,
    // Apple la place dans le jeton, puis on donne la valeur en clair à Firebase qui vérifie la correspondance.

    // Appelée au moment où l'utilisateur touche le bouton Apple
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        errorMessage = ""
        let nonce = Self.nonceAleatoire()
        nonceApple = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    // Appelée quand Apple a répondu
    func handleAppleCompletion(_ resultat: Result<ASAuthorization, Error>) async {
        await executer {
            let autorisation = try resultat.get()

            guard let identifiant = autorisation.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = self.nonceApple,
                  let jetonData = identifiant.identityToken,
                  let jeton = String(data: jetonData, encoding: .utf8) else {
                throw ErreurConnexion.jetonManquant("Apple")
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: jeton,
                rawNonce: nonce,
                fullName: identifiant.fullName
            )

            let connexion = try await Auth.auth().signIn(with: credential)
            self.user = connexion.user
        }
        nonceApple = nil
    }

    // Chaîne aléatoire générée avec le générateur cryptographique du système
    private static func nonceAleatoire(longueur: Int = 32) -> String {
        let caracteres = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var octets = [UInt8](repeating: 0, count: longueur)
        let statut = SecRandomCopyBytes(kSecRandomDefault, longueur, &octets)
        precondition(statut == errSecSuccess, "Impossible de générer un nonce sécurisé")
        return String(octets.map { caracteres[Int($0) % caracteres.count] })
    }

    private static func sha256(_ texte: String) -> String {
        SHA256.hash(data: Data(texte.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private enum ErreurConnexion: LocalizedError {
        case jetonManquant(String)

        var errorDescription: String? {
            switch self {
            case .jetonManquant(let fournisseur):
                return "\(fournisseur) n'a pas renvoyé de jeton d'identité."
            }
        }
    }

    func signOut() {
        do {
            // On déconnecte aussi Google, sinon le même compte serait reproposé automatiquement
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
            errorMessage = ""
        } catch {
            errorMessage = message(pour: error)
        }
    }

    // Lance un appel Firebase : gère le chargement et transforme l'erreur en message lisible
    private func executer(_ action: () async throws -> Void) async {
        errorMessage = ""
        isLoading = true
        do {
            try await action()
            isAuthenticated = user != nil
        } catch {
            errorMessage = message(pour: error)
        }
        isLoading = false
    }

    // Messages en français pour les erreurs les plus courantes
    private func message(pour erreur: Error) -> String {
        let erreurNS = erreur as NSError

        // Erreurs renvoyées par Apple
        if erreurNS.domain == ASAuthorizationError.errorDomain {
            switch ASAuthorizationError.Code(rawValue: erreurNS.code) {
            case .canceled:
                return ""
            case .unknown:
                // Cas typique sans compte Apple Developer payant : capability absente
                return "Sign in with Apple n'est pas disponible : l'app doit être signée avec un compte Apple Developer payant."
            default:
                return "Connexion Apple impossible : \(erreur.localizedDescription)"
            }
        }

        // L'utilisateur a fermé la fenêtre Google : ce n'est pas une erreur à afficher
        if erreurNS.domain == kGIDSignInErrorDomain {
            if erreurNS.code == GIDSignInError.canceled.rawValue {
                return ""
            }
            return "Connexion Google impossible : \(erreur.localizedDescription)"
        }

        guard let code = AuthErrorCode(rawValue: (erreur as NSError).code) else {
            return erreur.localizedDescription
        }

        switch code {
        case .invalidEmail:
            return "Adresse email invalide."
        case .emailAlreadyInUse:
            return "Un compte existe déjà avec cet email."
        case .weakPassword:
            return "Mot de passe trop faible (6 caractères minimum)."
        case .wrongPassword, .invalidCredential, .userNotFound:
            return "Email ou mot de passe incorrect."
        case .userDisabled:
            return "Ce compte a été désactivé."
        case .networkError:
            return "Pas de connexion Internet."
        case .tooManyRequests:
            return "Trop de tentatives, réessaie dans quelques minutes."
        case .operationNotAllowed:
            return "Ce mode de connexion n'est pas activé dans la console Firebase."
        case .accountExistsWithDifferentCredential:
            return "Cet email est déjà utilisé avec un autre mode de connexion."
        default:
            return erreur.localizedDescription
        }
    }
}
