#!/usr/bin/env bash
# Reproduit exactement la requête d'inscription envoyée par l'application
# mobile, qui répond 500 sur https://ebebfinance.com/api/auth/inscription
#
# L'app envoie du multipart/form-data avec l'en-tête Accept: application/json,
# et aucun en-tête Authorization (l'inscription est une route publique).
#
# Usage : renseigner trois images puis lancer
#   RECTO=~/recto.jpg VERSO=~/verso.jpg SELFIE=~/selfie.jpg ./reproduire-inscription.sh

set -euo pipefail

BASE_URL="${BASE_URL:-https://ebebfinance.com/api}"
RECTO="${RECTO:?chemin vers l'image recto requis}"
VERSO="${VERSO:?chemin vers l'image verso requis}"
SELFIE="${SELFIE:?chemin vers le selfie requis}"

# -i affiche les en-têtes de réponse en plus du corps.
curl -i -X POST "$BASE_URL/auth/inscription" \
  -H "Accept: application/json" \
  -F "nom=JOHN" \
  -F "prenom=DAN" \
  -F "telephone=+2250544108656" \
  -F "sexe=HOMME" \
  -F "date_naissance=1990-01-10" \
  -F "lieu_naissance=NEW YORK" \
  -F "situation_familiale=celibataire" \
  -F "email=sandrine.yapo14@gmail.com" \
  -F "numero_cnps=CNPS1234567" \
  -F "numero_cmu=CMU1234567" \
  -F "ville=ABIDJAN" \
  -F "quartier=ABIDJAN" \
  -F "adresse_postale=ABIDJAN" \
  -F "profession=ANALYSTE" \
  -F "metier=ANALYSTE" \
  -F "categorie_professionnelle=PRESTATAIRE DE SERVICES" \
  -F "montant_revenu=3456778" \
  -F "date_debut_activite=2021-01-12" \
  -F "ville_activite=ABIDJAN" \
  -F "quartier_activite=RIVIERA" \
  -F "commune_sous_prefecture_activite=COCODY" \
  -F "type_document=CNI" \
  -F "numero_document=CI1234567" \
  -F "document_etablie_le=2024-01-17" \
  -F "document_expire_le=2031-01-23" \
  -F "montant_cotisation_regime_base=165925" \
  -F "montant_cotisation_regime_complementaire=41481" \
  -F "montant_cotisation_mensuelle=207407" \
  -F "montant_cotisation_trimestrielle=622220" \
  -F "url_recto=@${RECTO}" \
  -F "url_verso=@${VERSO}" \
  -F "url_selfie=@${SELFIE}"

# ── Piste principale ────────────────────────────────────────────────────────
# `categorie_professionnelle` : l'app envoie le libellé du menu déroulant,
# alors que la collection Postman envoie le code « A5 ». Ce champ n'est pas
# contrôlé à la validation (une valeur bidon comme "ZZZ" passe), il est donc
# consommé plus loin — profil typique d'un champ qui fait tomber le traitement.
#
# Pour tester : relancer la commande ci-dessus en remplaçant simplement
#   -F "categorie_professionnelle=PRESTATAIRE DE SERVICES"
# par
#   -F "categorie_professionnelle=A5"
# en changeant aussi le téléphone et l'e-mail (contrainte d'unicité).
