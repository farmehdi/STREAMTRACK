-- ============================================================
-- StreamTrack — schema.sql
-- Base de données SQLite pour suivre sa consommation de streaming
-- et calculer le coût par heure visionnée par plateforme.
--
-- Auteur  : [Votre nom]
-- Moteur  : SQLite 3
-- Usage   : sqlite3 streamtrack.db < schema.sql
-- ============================================================

-- Activation des clés étrangères.
-- Par défaut, SQLite ne vérifie PAS les contraintes FOREIGN KEY.
-- Ce PRAGMA doit être activé à chaque connexion (réglage de session,
-- pas de la base). Sans lui, on pourrait insérer des IDs inexistants
-- sans aucune erreur. (Cours 4 — Michoud)
PRAGMA foreign_keys = ON;


-- ============================================================
-- TABLE : platforms
-- Représente les plateformes de streaming auxquelles l'utilisateur
-- est abonné (Netflix, Disney+, Prime Video…).
-- ============================================================
CREATE TABLE IF NOT EXISTS "platforms" (
    "id"                 INTEGER,
    -- Nom de la plateforme. UNIQUE : pas deux fois le même abonnement.
    "name"               TEXT    NOT NULL UNIQUE,
    -- Prix mensuel en euros. REAL et non INTEGER pour conserver
    -- les centimes (ex : 15.99 €). Un INTEGER tronquerait 15.99 → 15.
    -- CHECK > 0 : un abonnement gratuit sort du périmètre du projet.
    "monthly_price"      REAL    NOT NULL CHECK("monthly_price" > 0),
    -- Devise de facturation. DEFAULT 'EUR' : valeur utilisée si
    -- aucune devise n'est précisée à l'insertion.
    "currency"           TEXT    NOT NULL DEFAULT 'EUR',
    -- Date de début d'abonnement. NUMERIC car SQLite n'a pas de type
    -- DATE dédié — il stocke les dates au format ISO ('2024-01-15')
    -- et les gère correctement avec ce type. (Cours 3 — Michoud)
    "subscription_start" NUMERIC NOT NULL,

    PRIMARY KEY("id")
);


-- ============================================================
-- TABLE : users
-- Les membres du foyer qui regardent du contenu.
-- Permet de distinguer les habitudes de consommation par profil.
-- ============================================================
CREATE TABLE IF NOT EXISTS "users" (
    "id"         INTEGER,
    -- Pseudo unique par profil (ex : "Papa", "Alice", "Enfant1").
    "username"   TEXT    NOT NULL UNIQUE,
    -- Email facultatif : un profil enfant peut ne pas en avoir.
    -- UNIQUE tout de même : si renseigné, pas de doublon.
    "email"      TEXT    UNIQUE,
    -- Horodatage de création du profil. NUMERIC pour les dates/heures.
    -- DEFAULT CURRENT_TIMESTAMP : SQLite remplit automatiquement
    -- si aucune valeur n'est fournie à l'insertion. (Cours 3 — Michoud)
    "created_at" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY("id")
);


-- ============================================================
-- TABLE : contents
-- Catalogue de tout le contenu visioable : films, séries et épisodes.
--
-- Choix de conception clé — une seule table pour tout :
--   - type = 'movie'   → film standalone, parent_id NULL
--   - type = 'series'  → série (conteneur), parent_id NULL, duration_min NULL
--   - type = 'episode' → épisode, parent_id pointe vers la série parente
--
-- Cette auto-référence évite une table séparée pour les épisodes
-- et simplifie les jointures. (Normalisation — Cours 3 — Michoud)
-- ============================================================
CREATE TABLE IF NOT EXISTS "contents" (
    "id"           INTEGER,
    -- Clé étrangère vers la plateforme qui propose ce contenu.
    -- ON DELETE CASCADE : si une plateforme est supprimée, tout son
    -- catalogue l'est aussi. (Cours 4 — Michoud)
    "platform_id"  INTEGER NOT NULL,
    -- Auto-référence : NULL pour les films et séries, ID de la série
    -- parente pour les épisodes.
    -- ON DELETE CASCADE : supprimer une série supprime ses épisodes.
    "parent_id"    INTEGER,
    -- Titre du film, de la série ou de l'épisode.
    "title"        TEXT    NOT NULL,
    -- Type de contenu. CHECK avec IN pour n'autoriser que 3 valeurs.
    -- SQLite n'a pas de type ENUM, on simule avec CHECK. (Cours 3 — Michoud)
    "type"         TEXT    NOT NULL CHECK("type" IN ('movie', 'series', 'episode')),
    -- Durée en minutes. INTEGER suffisant (pas de décimales utiles).
    -- NULL autorisé pour les séries (sans durée propre).
    -- CHECK > 0 uniquement si la valeur est renseignée.
    "duration_min" INTEGER CHECK("duration_min" > 0),
    -- Numéro de saison, NULL pour les films.
    "season"       INTEGER CHECK("season" > 0),
    -- Numéro d'épisode, NULL pour les films et les séries.
    "episode"      INTEGER CHECK("episode" > 0),
    -- Année de sortie, pour l'affichage et les filtres.
    "release_year" INTEGER CHECK("release_year" > 1900),

    PRIMARY KEY("id"),
    FOREIGN KEY("platform_id") REFERENCES "platforms"("id") ON DELETE CASCADE,
    FOREIGN KEY("parent_id")   REFERENCES "contents"("id")  ON DELETE CASCADE
);


-- ============================================================
-- TABLE : watch_history
-- Chaque session de visionnage : qui, quoi, quand, combien de temps.
-- C'est la table centrale pour le calcul du coût par heure.
-- ============================================================
CREATE TABLE IF NOT EXISTS "watch_history" (
    "id"                   INTEGER,
    -- Qui a regardé.
    "user_id"              INTEGER NOT NULL,
    -- Quoi (film ou épisode — on ne pointe jamais vers une série).
    "content_id"           INTEGER NOT NULL,
    -- Quand. NUMERIC pour les horodatages, DEFAULT CURRENT_TIMESTAMP.
    "watched_at"           NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Durée réelle visionnée en minutes (peut être < durée du contenu
    -- si l'utilisateur a abandonné). CHECK > 0 : une session de 0 min
    -- n'a pas de sens.
    "watched_duration_min" INTEGER NOT NULL CHECK("watched_duration_min" > 0),
    -- Booléen SQLite : 0 = non terminé, 1 = terminé.
    -- SQLite n'a pas de type BOOLEAN. Convention du cours : 0/1. (Cours 3)
    "completed"            INTEGER NOT NULL DEFAULT 0 CHECK("completed" IN (0, 1)),

    PRIMARY KEY("id"),
    -- ON DELETE CASCADE : si un utilisateur ou un contenu est supprimé,
    -- son historique de visionnage l'est aussi.
    FOREIGN KEY("user_id")    REFERENCES "users"("id")    ON DELETE CASCADE,
    FOREIGN KEY("content_id") REFERENCES "contents"("id") ON DELETE CASCADE
);


-- ============================================================
-- INDEX
-- Les index accélèrent les recherches sur les colonnes fréquemment
-- utilisées dans les WHERE et JOIN, au prix d'un léger surcoût
-- à l'écriture. (Cours projet — Michoud)
-- ============================================================

-- Recherches fréquentes : "tous les contenus d'une plateforme"
CREATE INDEX IF NOT EXISTS "idx_contents_platform"
    ON "contents"("platform_id");

-- Recherches fréquentes : "tous les épisodes d'une série"
CREATE INDEX IF NOT EXISTS "idx_contents_parent"
    ON "contents"("parent_id");

-- Recherches fréquentes : "tout l'historique d'un utilisateur"
CREATE INDEX IF NOT EXISTS "idx_watch_history_user"
    ON "watch_history"("user_id");

-- Recherches fréquentes : "toutes les sessions pour un contenu donné"
CREATE INDEX IF NOT EXISTS "idx_watch_history_content"
    ON "watch_history"("content_id");

-- Tri chronologique de l'historique (ORDER BY watched_at)
CREATE INDEX IF NOT EXISTS "idx_watch_history_date"
    ON "watch_history"("watched_at");


-- ============================================================
-- VUE : v_watch_details
-- Table virtuelle qui pré-joint les 4 tables principales.
-- Objectif : simplifier toutes les requêtes d'analyse.
-- Chaque SELECT sur cette vue rejoue la jointure automatiquement.
-- (Cours 5 — Vues — Michoud)
-- ============================================================
CREATE VIEW IF NOT EXISTS "v_watch_details" AS
SELECT
    wh."id"                   AS "session_id",
    u."username",
    p."name"                  AS "platform",
    p."monthly_price",
    p."currency",
    c."title",
    c."type",
    c."season",
    c."episode",
    c."duration_min"          AS "content_duration_min",
    wh."watched_at",
    wh."watched_duration_min",
    wh."completed"
FROM "watch_history" wh
JOIN "users"    u ON u."id" = wh."user_id"
JOIN "contents" c ON c."id" = wh."content_id"
JOIN "platforms" p ON p."id" = c."platform_id";


-- ============================================================
-- VUE : v_platform_roi
-- Calcule le "ROI" (retour sur investissement) de chaque plateforme :
-- coût mensuel divisé par le total d'heures visionnées ce mois.
-- Cette vue est un agrégat — elle se recalcule à chaque appel.
-- (Cours 5 — Agrégation avec vues — Michoud)
-- ============================================================
CREATE VIEW IF NOT EXISTS "v_platform_roi" AS
SELECT
    p."name"                                              AS "platform",
    p."monthly_price",
    -- Total des minutes visionnées sur cette plateforme, converti en heures
    ROUND(SUM(wh."watched_duration_min") / 60.0, 2)      AS "total_hours_watched",
    -- Coût par heure : prix mensuel / heures totales
    -- NULLIF évite la division par zéro si aucune session n'existe
    ROUND(
        p."monthly_price" / NULLIF(SUM(wh."watched_duration_min") / 60.0, 0),
        2
    )                                                     AS "cost_per_hour"
FROM "platforms" p
LEFT JOIN "contents"      c  ON c."platform_id" = p."id"
LEFT JOIN "watch_history" wh ON wh."content_id" = c."id"
GROUP BY p."id", p."name", p."monthly_price";
