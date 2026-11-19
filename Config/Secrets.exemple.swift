//
//  Secrets.exemple.swift
//  GGStats
//
//  MODÈLE du fichier qui contient la clé API Riot.
//  Ce fichier n'est compilé par aucune cible : il sert seulement d'exemple.
//
//  Pour configurer le projet :
//    ./scripts/changer-cle-api.sh RGAPI-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
//  (ou copier ce fichier vers Partage/Secrets.swift et y coller la clé)
//
//  Partage/Secrets.swift est ignoré par git : la clé ne part jamais sur GitHub.
//

enum Secrets {
    static let cleAPIRiot = "RGAPI-a-remplacer"
}
