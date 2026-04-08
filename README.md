# StreamTrack 

## Sujet et contexte

StreamTrack est une base de données conçue pour **suivre sa consommation personnelle de plateformes de streaming** (Netflix, Disney+, Prime Video, Apple TV+) et en **optimiser les coûts**.

Le problème que cette base résout : un abonnement à 15 €/mois paraît raisonnable, mais si on ne regarde que 3 heures par mois, le coût réel est de **5 €/heure**. StreamTrack permet de calculer le **coût par heure visionnée** pour chaque plateforme, et ainsi de décider quels abonnements valent vraiment leur prix.

## Utilisateurs cibles

- Un particulier souscrit à plusieurs plateformes simultanément qui veut savoir lesquelles rentabiliser ou résilier.
- Un foyer partageant plusieurs comptes qui veut répartir les coûts équitablement selon la consommation de chacun.

## Fonctionnalités principales

- Enregistrer les plateformes et leur coût d'abonnement mensuel
- Cataloguer les contenus regardés (films et séries, avec distinction des épisodes)
- Consigner chaque session de visionnage avec sa durée réelle
- Calculer automatiquement le **coût par heure** par plateforme (le "ROI" de l'abonnement)

---

## Sources de données

### Plateformes et tarifs
Les 4 plateformes (Netflix, Disney+, Prime Video, Apple TV+) et leurs prix mensuels sont basés sur les **tarifs publics officiels début 2024**, consultables directement sur les sites des plateformes.

### Titres et durées des contenus
Les titres de films et séries sont des **œuvres réelles** existant sur ces plateformes en 2023-2024 (Oppenheimer, Squid Game, Ted Lasso, The Crown S6, etc.). Les durées sont approximées d'après les durées réelles connues et vérifiables sur [IMDb](https://www.imdb.com).

### Historique de visionnage
L'historique de visionnage (sessions, dates, durées regardées, abandons) est **entièrement fictif et généré avec l'aide d'un LLM (Claude, Anthropic)**. Ces données simulent de façon réaliste 3 mois de consommation (janvier–mars 2024) pour 2 utilisateurs. Elles n'ont aucune source réelle — c'est de la fiction réaliste construite pour rendre les analyses intéressantes.

---

## Structure du dépôt

```
streamtrack/
├── README.md        ← Ce fichier
├── DESIGN.md        ← Conception, schéma ER, choix techniques, limitations
├── schema.sql       ← Création des tables, index, vues (structure de la base)
├── seed.sql         ← Insertion des données de test (peuplement)
├── queries.sql      ← Requêtes de manipulation CRUD (usage quotidien)
└── analysis.sql     ← Requêtes d'analyse (CTEs, agrégations, ROI)
```

---

## Contenu des fichiers SQL

### `schema.sql`
Crée la **structure complète** de la base : 4 tables, 5 index et 2 vues.

- `PRAGMA foreign_keys = ON` — active la vérification des clés étrangères (désactivées par défaut dans SQLite)
- **4 tables** : `platforms`, `users`, `contents`, `watch_history` avec toutes leurs contraintes (`NOT NULL`, `CHECK`, `UNIQUE`, `DEFAULT`, `FOREIGN KEY`, `ON DELETE CASCADE`)
- **5 index** sur les colonnes les plus fréquemment utilisées dans les jointures et tris
- `CREATE VIEW v_watch_details` — jointure pré-calculée des 4 tables pour simplifier les requêtes
- `CREATE VIEW v_platform_roi` — calcule automatiquement le coût par heure par plateforme

### `seed.sql`
Remplit la base avec des données réalistes simulant **3 mois de consommation** (janvier–mars 2024) :
- 4 plateformes avec leurs tarifs réels
- 2 utilisateurs (Alice et Tom)
- 29 contenus : 9 films, 5 séries, 15 épisodes
- 32 sessions de visionnage avec dates, durées et statut de complétion

Toutes les insertions dans `watch_history` utilisent des **sous-requêtes sur les titres** plutôt que des IDs en dur, pour garantir la robustesse du script.

### `queries.sql`
Requêtes CRUD simulant l'**usage quotidien** de la base, toutes commentées :
- **INSERT** : ajout d'une nouvelle plateforme, d'un utilisateur, d'un contenu, d'une session
- **SELECT** : consultation du catalogue, de l'historique, des contenus jamais regardés
- **UPDATE** : changement de tarif, correction d'une session mal enregistrée
- **DELETE** : résiliation d'une plateforme (avec `ON DELETE CASCADE`), suppression d'une session

### `analysis.sql`
8 requêtes d'analyse qui répondent à des questions concrètes sur la consommation :

| # | Analyse | Concepts SQL utilisés |
|---|---|---|
| 1 | Heures visionnées par plateforme | `LEFT JOIN`, `GROUP BY`, `SUM`, `ROUND` |
| 2 | ROI par plateforme avec verdict | Vue `v_platform_roi` + `CASE` |
| 3 | Top 10 contenus les plus regardés | **CTE** + `JOIN` + `ORDER BY` |
| 4 | ROI détaillé par utilisateur | **2 CTEs chaînées** |
| 5 | Taux de complétion par plateforme | `GROUP BY`, `HAVING`, `SUM(CASE WHEN…)` |
| 6 | Évolution mensuelle de la consommation | `strftime`, `GROUP BY`, `COUNT DISTINCT` |
| 7 | Contenus abandonnés | **CTE** + agrégation conditionnelle |
| 8 | Rapport final de recommandation | **CTE complexe** + `COALESCE` + `NULLS LAST` |

---

## Lancer le projet

```bash
# 1. Créer la base et le schéma
sqlite3 streamtrack.db < schema.sql

# 2. Peupler avec les données de test
sqlite3 streamtrack.db < seed.sql

# 3. Tester les requêtes de manipulation
sqlite3 streamtrack.db < queries.sql

# 4. Lancer les analyses
sqlite3 -header -column streamtrack.db < analysis.sql
```

Ou avec **DB Browser for SQLite** (interface graphique recommandée) :
1. "New Database" → nommer `streamtrack.db`
2. Onglet "Execute SQL" → coller et exécuter chaque fichier dans l'ordre
3. Cliquer "Write Changes" après chaque INSERT/UPDATE/DELETE

> **Moteur** : SQLite 3. Aucune installation de serveur requise.
> **Interface recommandée** : [DB Browser for SQLite](https://sqlitebrowser.org/dl/)

