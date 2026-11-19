#!/bin/zsh
#
# changer-cle-api.sh
# Remplace la clé API Riot utilisée par GGStats (app iPhone, montre et widget).
#
# Usage :
#   ./scripts/changer-cle-api.sh RGAPI-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#   ./scripts/changer-cle-api.sh            (la clé est alors demandée, sans s'afficher)
#
# La clé est écrite dans Partage/Secrets.swift, qui est ignoré par git.
# Nouvelle clé de développement : https://developer.riotgames.com (bouton "Regenerate API Key").
#

set -e

RACINE="$(cd "$(dirname "$0")/.." && pwd)"
FICHIER="$RACINE/Partage/Secrets.swift"

CLE="$1"
if [[ -z "$CLE" ]]; then
    read -rs "CLE?Colle la nouvelle clé API Riot : "
    echo
fi
CLE="${CLE//[[:space:]]/}"

# 1. Format attendu : RGAPI- suivi d'un identifiant de 36 caractères
if [[ ! "$CLE" =~ '^RGAPI-[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' ]]; then
    echo "❌ Format invalide. Attendu : RGAPI-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    exit 1
fi

# 2. On teste la clé auprès de Riot avant de l'enregistrer (endpoint léger : état du serveur EUW)
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -H "X-Riot-Token: $CLE" \
    "https://euw1.api.riotgames.com/lol/status/v4/platform-data" || echo "000")

case "$CODE" in
    200) echo "✅ Clé acceptée par Riot." ;;
    401|403)
        echo "❌ Riot refuse cette clé (HTTP $CODE) : elle est invalide ou déjà expirée."
        exit 1 ;;
    000)
        echo "⚠️  Impossible de joindre Riot (pas de réseau ?). La clé est enregistrée sans être vérifiée." ;;
    *)
        echo "⚠️  Réponse inattendue de Riot (HTTP $CODE). La clé est enregistrée quand même." ;;
esac

# 3. Écriture du fichier secret (ignoré par git)
cat > "$FICHIER" <<EOF
//
//  Secrets.swift
//  GGStats
//
//  Fichier LOCAL qui contient la clé API Riot.
//  NE PAS COMMITTER : ce fichier est dans .gitignore.
//  Mis à jour le $(date "+%d/%m/%Y à %H:%M") par scripts/changer-cle-api.sh
//

enum Secrets {
    static let cleAPIRiot = "$CLE"
}
EOF

echo "🔑 Clé enregistrée dans Partage/Secrets.swift (non versionné)."
echo "   Relance l'app depuis Xcode pour l'utiliser. Une clé de développement expire après 24 h."
