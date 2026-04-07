# StreamTrack 🎬

## Sujet et contexte

StreamTrack est une base de données conçue pour **suivre sa consommation personnelle de plateformes de streaming** (Netflix, Disney+, Prime Video, etc.) et en **optimiser les coûts**.

Le problème que cette base résout : un abonnement à 15 €/mois paraît raisonnable, mais si on ne regarde que 3 heures par mois, le coût réel est de **5 €/heure**. StreamTrack permet de calculer le **coût par heure visionnée** pour chaque plateforme, et ainsi de décider quels abonnements valent vraiment leur prix.

## Utilisateurs cibles

- Un particulier souscrit à plusieurs plateformes simultanément et veut savoir lesquelles rentabiliser ou résilier.
- Un foyer partageant plusieurs comptes qui veut répartir les coûts équitablement selon la consommation de chacun.

## Fonctionnalités principales

- Enregistrer les plateformes et leur coût d'abonnement mensuel
- Cataloguer les contenus regardés (films et séries, avec distinction des épisodes)
- Consigner chaque session de visionnage avec sa durée réelle
- Calculer automatiquement le **coût par heure** par plateforme (le "ROI" de l'abonnement)

## Sources de données

- Données de plateformes et de contenus : générées manuellement et avec l'aide d'un LLM (titres réalistes, durées cohérentes)
- Historique de visionnage : généré de façon réaliste pour simuler 3 mois de consommation

## Structure du dépôt

```
streamtrack/
├── README.md        ← Ce fichier
├── DESIGN.md        ← Conception, schéma ER, choix techniques
├── schema.sql       ← Création des tables, index, vues
├── seed.sql         ← Insertion des données de test
├── queries.sql      ← Requêtes de manipulation (INSERT, UPDATE, DELETE)
├── analysis.sql     ← Requêtes d'analyse (CTEs, agrégations, ROI)
└── data/            ← Fichiers CSV optionnels
```

## Lancer le projet

```bash
# Créer la base et le schéma
sqlite3 streamtrack.db < schema.sql

# Peupler avec les données de test
sqlite3 streamtrack.db < seed.sql

# Lancer les analyses
sqlite3 -header -column streamtrack.db < analysis.sql
```

> **Moteur** : SQLite 3. Aucune installation de serveur requise.
