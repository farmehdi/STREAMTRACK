-- ============================================================
-- StreamTrack — queries.sql
-- Requêtes de manipulation simulant l'usage quotidien de la base.
-- Couvre les 4 opérations CRUD : INSERT, SELECT, UPDATE, DELETE.
--
-- Chaque requête est commentée pour expliquer ce qu'elle fait
-- et pourquoi. (Exigence projet — Michoud)
-- ============================================================

PRAGMA foreign_keys = ON;


-- ============================================================
-- C — CREATE (INSERT INTO)
-- Scénarios : nouvel abonnement, nouveau profil, nouveau visionnage
-- ============================================================

-- Scénario 1 : On souscrit à une nouvelle plateforme (Max).
-- On insère sans préciser l'id → SQLite l'auto-incrémente. (Cours 4)
INSERT INTO "platforms" ("name", "monthly_price", "currency", "subscription_start")
VALUES ('Max', 9.99, 'EUR', '2024-04-01');

-- Scénario 2 : Un troisième membre du foyer crée un profil.
INSERT INTO "users" ("username", "email", "created_at")
VALUES ('Julie', 'julie@email.com', '2024-04-01 09:00:00');

-- Scénario 3 : On ajoute un film disponible sur Max.
-- On utilise une sous-requête pour trouver l'id de Max
-- plutôt que de coder l'id en dur (plus robuste).
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "release_year")
VALUES (
    (SELECT "id" FROM "platforms" WHERE "name" = 'Max'),
    NULL,
    'Dune: Deuxième Partie',
    'movie',
    166,
    2024
);

-- Scénario 4 : Julie vient de regarder ce film en entier.
-- On insère une session dans watch_history.
-- Les deux clés étrangères sont résolues par sous-requête.
INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES (
    (SELECT "id" FROM "users"    WHERE "username" = 'Julie'),
    (SELECT "id" FROM "contents" WHERE "title"    = 'Dune: Deuxième Partie'),
    '2024-04-05 20:00:00',
    166,
    1
);

-- Scénario 5 : Ajout d'une série et de ses épisodes sur Max.
-- D'abord la série (parent), ensuite les épisodes qui y font référence.
-- L'ordre d'insertion respecte les contraintes FOREIGN KEY. (Cours 4)
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "release_year")
VALUES (
    (SELECT "id" FROM "platforms" WHERE "name" = 'Max'),
    NULL, 'The Last of Us', 'series', NULL, 2023
);

-- Épisodes de The Last of Us (parent_id récupéré dynamiquement)
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "season", "episode", "release_year")
VALUES
    (
        (SELECT "id" FROM "platforms" WHERE "name" = 'Max'),
        (SELECT "id" FROM "contents"  WHERE "title" = 'The Last of Us'),
        'The Last of Us S1E1 - When You''re Lost in the Darkness',
        'episode', 81, 1, 1, 2023
    ),
    (
        (SELECT "id" FROM "platforms" WHERE "name" = 'Max'),
        (SELECT "id" FROM "contents"  WHERE "title" = 'The Last of Us'),
        'The Last of Us S1E2 - Infected',
        'episode', 55, 1, 2, 2023
    );


-- ============================================================
-- R — READ (SELECT)
-- Requêtes de consultation courantes
-- ============================================================

-- Consulter tous les abonnements actifs avec leur coût mensuel.
SELECT "name", "monthly_price", "currency", "subscription_start"
FROM "platforms"
ORDER BY "monthly_price" DESC;

-- Voir le catalogue complet d'une plateforme (Netflix).
-- On filtre sur le type 'movie' et 'series' uniquement (pas les épisodes).
SELECT "title", "type", "release_year", "duration_min"
FROM "contents"
WHERE "platform_id" = (SELECT "id" FROM "platforms" WHERE "name" = 'Netflix')
  AND "type" IN ('movie', 'series')
ORDER BY "type", "release_year" DESC;

-- Voir les 10 dernières sessions de visionnage de tous les utilisateurs.
-- On utilise la vue v_watch_details créée dans schema.sql. (Cours 5 — vues)
SELECT "username", "platform", "title", "watched_at", "watched_duration_min", "completed"
FROM "v_watch_details"
ORDER BY "watched_at" DESC
LIMIT 10;

-- Voir toutes les sessions d'Alice uniquement.
SELECT "platform", "title", "watched_at", "watched_duration_min", "completed"
FROM "v_watch_details"
WHERE "username" = 'Alice'
ORDER BY "watched_at" DESC;

-- Lister les contenus jamais regardés (aucune session dans watch_history).
-- Utilise un LEFT JOIN + WHERE IS NULL : technique vue en Cours 2.
SELECT c."title", c."type", p."name" AS "platform"
FROM "contents" c
JOIN "platforms" p ON p."id" = c."platform_id"
LEFT JOIN "watch_history" wh ON wh."content_id" = c."id"
WHERE wh."id" IS NULL
  AND c."type" IN ('movie', 'episode')
ORDER BY p."name", c."title";


-- ============================================================
-- U — UPDATE
-- Scénarios : changement de prix, correction d'une durée
-- ============================================================

-- Scénario 1 : Netflix augmente son tarif en avril 2024.
-- On met à jour uniquement la ligne concernée grâce au WHERE.
-- ⚠️ Sans WHERE, TOUTES les plateformes seraient modifiées ! (Cours 4)
UPDATE "platforms"
SET "monthly_price" = 6.99
WHERE "name" = 'Netflix';

-- Vérification immédiate après la mise à jour.
SELECT "name", "monthly_price" FROM "platforms" WHERE "name" = 'Netflix';

-- Scénario 2 : On corrige la durée d'un film mal renseignée.
-- Rebel Moon dure en réalité 122 min (version Director's Cut = 135 min).
UPDATE "contents"
SET "duration_min" = 122
WHERE "title" = 'Rebel Moon'
  AND "type" = 'movie';

-- Scénario 3 : Alice a mal enregistré une session (durée saisie en double).
-- On corrige la session du 5 janvier 2024 sur Oppenheimer.
UPDATE "watch_history"
SET "watched_duration_min" = 90,
    "completed" = 0
WHERE "user_id"    = (SELECT "id" FROM "users"    WHERE "username" = 'Alice')
  AND "content_id" = (SELECT "id" FROM "contents" WHERE "title"    = 'Oppenheimer')
  AND "watched_at" = '2024-01-05 20:30:00';


-- ============================================================
-- D — DELETE
-- Scénarios : résiliation d'abonnement, suppression d'une session
-- ============================================================

-- Scénario 1 : On résilie l'abonnement Apple TV+.
-- Grâce à ON DELETE CASCADE défini dans schema.sql,
-- la suppression de la plateforme entraîne automatiquement
-- la suppression de tous ses contenus ET de leur historique. (Cours 4)
--
-- ⚠️ Dans un vrai projet, on préférerait un "soft delete"
-- (colonne "active" = 0) pour conserver l'historique.
DELETE FROM "platforms"
WHERE "name" = 'Apple TV+';

-- Vérification : les contenus Apple TV+ ont bien disparu.
SELECT COUNT(*) AS "contenus_apple" FROM "contents"
WHERE "platform_id" NOT IN (SELECT "id" FROM "platforms");

-- Scénario 2 : Tom veut supprimer une session qu'il a enregistrée par erreur.
-- On supprime uniquement la session spécifique (pas tout l'historique de Tom).
DELETE FROM "watch_history"
WHERE "user_id"    = (SELECT "id" FROM "users"    WHERE "username" = 'Tom')
  AND "content_id" = (SELECT "id" FROM "contents" WHERE "title"    = 'Wish')
  AND "watched_at" = '2024-01-06 16:00:00';
