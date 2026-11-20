//
//  AuthView.swift
//  GGStats
//
//  Écran de connexion / inscription par email avec Firebase.
//

import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct AuthView: View {
    @ObservedObject var authManager: AuthManager

    // Champs locaux à l'écran
    @State private var email = ""
    @State private var password = ""

    private var champsRemplis: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    var body: some View {
        ZStack {
            FondDegradeGG()

            ScrollView {
                VStack(spacing: 26) {
                    VStack(spacing: 8) {
                        Text("GGStats")
                            .font(.system(size: 52, weight: .black))
                            .foregroundStyle(.white)

                        Text("Connecte-toi pour continuer")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 60)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Email")
                            .font(.headline)
                            .foregroundStyle(.white)

                        TextField("exemple@mail.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.white)
                            .cornerRadius(14)

                        Text("Mot de passe")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.top, 6)

                        SecureField("6 caractères minimum", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(.white)
                            .cornerRadius(14)
                    }

                    if !authManager.errorMessage.isEmpty {
                        Text(authManager.errorMessage)
                            .foregroundStyle(.red)
                            .bold(true)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white.opacity(0.9))
                            .cornerRadius(12)
                    }

                    VStack(spacing: 14) {
                        Button {
                            Task {
                                await authManager.signIn(email: emailNettoye, password: password)
                            }
                        } label: {
                            Text("Se connecter")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.ggBleu, .ggViolet],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(radius: 8)
                        }

                        Button {
                            Task {
                                await authManager.signUp(email: emailNettoye, password: password)
                            }
                        } label: {
                            Text("Créer un compte")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.ggCarte)
                                .cornerRadius(16)
                        }
                    }
                    .disabled(!champsRemplis || authManager.isLoading)
                    .opacity(champsRemplis ? 1 : 0.6)

                    separateur

                    // Bouton officiel fourni par GoogleSignInSwift (respecte la charte Google)
                    GoogleSignInButton(scheme: .light, style: .wide, state: authManager.isLoading ? .disabled : .normal) {
                        Task {
                            await authManager.signInWithGoogle()
                        }
                    }
                    .disabled(authManager.isLoading)

                    // Bouton officiel Apple (nécessite un compte Apple Developer payant pour fonctionner)
                    SignInWithAppleButton(.signIn) { request in
                        authManager.prepareAppleRequest(request)
                    } onCompletion: { resultat in
                        Task {
                            await authManager.handleAppleCompletion(resultat)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 48)
                    .cornerRadius(10)
                    .disabled(authManager.isLoading)

                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var separateur: some View {
        HStack {
            Rectangle().frame(height: 1)
            Text("ou")
                .font(.subheadline)
            Rectangle().frame(height: 1)
        }
        .foregroundStyle(.white.opacity(0.6))
    }

    // Évite les erreurs "email invalide" à cause d'un espace en trop
    private var emailNettoye: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    AuthView(authManager: AuthManager())
}
