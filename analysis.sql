-- ============================================================
-- StreamTrack — analysis.sql
-- Requêtes d'analyse : extraire des informations utiles
-- pour optimiser ses abonnements de streaming.
--
-- Fonctionnalités SQL utilisées (Cours 1 à 5 — Michoud) :
--   JOIN, GROUP BY, HAVING, ORDER BY, agrégations
--   Sous-requêtes, CTEs (WITH … AS), Vues, CASE, ROUND
-- ============================================================

PRAGMA foreign_keys = ON;


-- ============================================================
-- ANALYSE 1 : Vue d'ensemble — heures visionnées par plateforme
-- Requête simple avec JOIN + GROUP BY + agrégation.
-- Objectif : savoir quelle plateforme est la plus utilisée.
-- ============================================================
SELECT
    p."name"                                              AS "Plateforme",
    COUNT(wh."id")                                        AS "Nb sessions",
    SUM(wh."watched_duration_min")                        AS "Total minutes",
    ROUND(SUM(wh."watched_duration_min") / 60.0, 1)      AS "Total heures"
FROM "platforms" p
-- LEFT JOIN pour garder les plateformes sans aucun visionnage
LEFT JOIN "contents"      c  ON c."platform_id" = p."id"
LEFT JOIN "watch_history" wh ON wh."content_id" = c."id"
GROUP BY p."id", p."name"
ORDER BY "Total heures" DESC;


-- ============================================================
-- ANALYSE 2 : ROI par plateforme — le "coût par heure"
-- Utilise la vue v_platform_roi créée dans schema.sql.
-- C'est la requête centrale du projet.
-- Objectif : identifier les abonnements rentables vs. à résilier.
-- ============================================================
SELECT
    "platform"        AS "Plateforme",
    "monthly_price"   AS "Prix/mois (€)",
    "total_hours_watched" AS "Heures visionnées",
    "cost_per_hour"   AS "Coût/heure (€)",
    -- Classement qualitatif avec CASE (Cours 1 — conditions)
    CASE
        WHEN "cost_per_hour" IS NULL  THEN '⚠️  Jamais regardé'
        WHEN "cost_per_hour" < 1.50   THEN '✅  Excellent ROI'
        WHEN "cost_per_hour" < 3.00   THEN '🟡  ROI correct'
        WHEN "cost_per_hour" < 5.00   THEN '🟠  ROI faible'
        ELSE                               '🔴  À résilier'
    END                               AS "Verdict"
FROM "v_platform_roi"
ORDER BY "cost_per_hour" ASC;


-- ============================================================
-- ANALYSE 3 : CTE — Top contenus les plus regardés
-- Utilise une CTE pour pré-calculer les totaux, puis jointure.
-- Objectif : connaître les titres qui génèrent le plus de visionnage.
-- (Cours 5 — CTEs — Michoud)
-- ============================================================
WITH "totaux_contenu" AS (
    -- CTE : total de minutes visionnées par contenu
    SELECT
        "content_id",
        COUNT(*)                                     AS "nb_sessions",
        SUM("watched_duration_min")                  AS "total_min",
        ROUND(SUM("watched_duration_min") / 60.0, 1) AS "total_heures"
    FROM "watch_history"
    GROUP BY "content_id"
)
SELECT
    c."title"               AS "Titre",
    c."type"                AS "Type",
    p."name"                AS "Plateforme",
    t."nb_sessions"         AS "Sessions",
    t."total_heures"        AS "Heures visionnées"
FROM "totaux_contenu" t
JOIN "contents"  c ON c."id" = t."content_id"
JOIN "platforms" p ON p."id" = c."platform_id"
ORDER BY t."total_min" DESC
LIMIT 10;


-- ============================================================
-- ANALYSE 4 : CTE chaînée — ROI détaillé par utilisateur ET plateforme
-- Deux CTEs : une calcule les minutes, l'autre joint avec les prix.
-- Objectif : voir qui consomme quoi et à quel coût réel.
-- (Cours 5 — plusieurs CTEs — Michoud)
-- ============================================================
WITH "minutes_par_user_platform" AS (
    -- CTE 1 : minutes visionnées par (utilisateur, plateforme)
    SELECT
        wh."user_id",
        p."id"                                           AS "platform_id",
        p."name"                                         AS "platform",
        p."monthly_price",
        SUM(wh."watched_duration_min")                   AS "total_min"
    FROM "watch_history" wh
    JOIN "contents"  c  ON c."id"  = wh."content_id"
    JOIN "platforms" p  ON p."id"  = c."platform_id"
    GROUP BY wh."user_id", p."id"
),
"roi_par_user" AS (
    -- CTE 2 : calcul du coût par heure à partir de la CTE 1
    SELECT
        m."user_id",
        m."platform",
        m."monthly_price",
        ROUND(m."total_min" / 60.0, 1)                  AS "heures",
        ROUND(m."monthly_price" / NULLIF(m."total_min" / 60.0, 0), 2) AS "cout_par_heure"
    FROM "minutes_par_user_platform" m
)
SELECT
    u."username"        AS "Utilisateur",
    r."platform"        AS "Plateforme",
    r."monthly_price"   AS "Prix/mois (€)",
    r."heures"          AS "Heures visionnées",
    r."cout_par_heure"  AS "Coût/heure (€)"
FROM "roi_par_user" r
JOIN "users" u ON u."id" = r."user_id"
ORDER BY u."username", r."cout_par_heure" ASC;


-- ============================================================
-- ANALYSE 5 : Taux de complétion par plateforme
-- GROUP BY + HAVING + agrégation conditionnelle avec CASE.
-- Objectif : voir si les contenus sont regardés jusqu'au bout.
-- HAVING filtre les groupes après GROUP BY. (Cours 2 — Michoud)
-- ============================================================
SELECT
    p."name"                                              AS "Plateforme",
    COUNT(wh."id")                                        AS "Total sessions",
    -- Compte uniquement les sessions complétées (completed = 1)
    SUM(CASE WHEN wh."completed" = 1 THEN 1 ELSE 0 END)  AS "Sessions complétées",
    -- Taux de complétion en pourcentage
    ROUND(
        100.0 * SUM(CASE WHEN wh."completed" = 1 THEN 1 ELSE 0 END)
        / COUNT(wh."id"),
        1
    )                                                     AS "Taux complétion (%)"
FROM "watch_history" wh
JOIN "contents"  c ON c."id"  = wh."content_id"
JOIN "platforms" p ON p."id"  = c."platform_id"
GROUP BY p."id", p."name"
-- HAVING : on ne garde que les plateformes avec au moins 3 sessions
HAVING COUNT(wh."id") >= 3
ORDER BY "Taux complétion (%)" DESC;


-- ============================================================
-- ANALYSE 6 : Activité mensuelle — évolution de la consommation
-- Extraction du mois depuis le champ NUMERIC watched_at avec strftime.
-- Objectif : voir si la consommation est régulière dans le temps.
-- ============================================================
SELECT
    strftime('%Y-%m', "watched_at")                      AS "Mois",
    COUNT(*)                                             AS "Sessions",
    ROUND(SUM("watched_duration_min") / 60.0, 1)         AS "Heures totales",
    COUNT(DISTINCT "user_id")                            AS "Utilisateurs actifs"
FROM "watch_history"
GROUP BY strftime('%Y-%m', "watched_at")
ORDER BY "Mois" ASC;


-- ============================================================
-- ANALYSE 7 : CTE + sous-requête — Contenu abandonné vs complété
-- Identifie les contenus souvent abandonnés (signe de mauvaise qualité
-- ou de contenu trop long).
-- ============================================================
WITH "stats_contenu" AS (
    SELECT
        "content_id",
        COUNT(*)                                            AS "total_sessions",
        SUM(CASE WHEN "completed" = 0 THEN 1 ELSE 0 END)   AS "abandons",
        SUM(CASE WHEN "completed" = 1 THEN 1 ELSE 0 END)   AS "completions"
    FROM "watch_history"
    GROUP BY "content_id"
)
SELECT
    c."title"                                             AS "Titre",
    c."type"                                              AS "Type",
    c."duration_min"                                      AS "Durée (min)",
    p."name"                                              AS "Plateforme",
    s."total_sessions"                                    AS "Sessions",
    s."abandons"                                          AS "Abandons",
    s."completions"                                       AS "Complétions",
    ROUND(100.0 * s."abandons" / s."total_sessions", 0)   AS "Taux abandon (%)"
FROM "stats_contenu" s
JOIN "contents"  c ON c."id"  = s."content_id"
JOIN "platforms" p ON p."id"  = c."platform_id"
-- Ne montre que les contenus avec au moins 1 abandon
WHERE s."abandons" > 0
ORDER BY "Taux abandon (%)" DESC;


-- ============================================================
-- ANALYSE 8 : Rapport final — Recommandation d'abonnements
-- CTE complexe combinant tout : coût, heures, verdict.
-- Requête de synthèse pour la présentation orale.
-- ============================================================
WITH "bilan_complet" AS (
    SELECT
        p."id"                                                AS "platform_id",
        p."name"                                             AS "platform",
        p."monthly_price",
        COUNT(DISTINCT wh."id")                              AS "nb_sessions",
        ROUND(SUM(wh."watched_duration_min") / 60.0, 1)     AS "heures_totales",
        ROUND(
            p."monthly_price" / NULLIF(SUM(wh."watched_duration_min") / 60.0, 0),
            2
        )                                                    AS "cout_par_heure"
    FROM "platforms" p
    LEFT JOIN "contents"      c  ON c."platform_id" = p."id"
    LEFT JOIN "watch_history" wh ON wh."content_id" = c."id"
    GROUP BY p."id", p."name", p."monthly_price"
)
SELECT
    "platform"          AS "Plateforme",
    "monthly_price"     AS "€/mois",
    "nb_sessions"       AS "Sessions",
    "heures_totales"    AS "Heures",
    COALESCE(CAST("cout_par_heure" AS TEXT), 'N/A') AS "€/heure",
    CASE
        WHEN "cout_par_heure" IS NULL THEN '🔴 Résilier — Jamais utilisé'
        WHEN "cout_par_heure" < 1.00  THEN '✅ Garder — Très rentable'
        WHEN "cout_par_heure" < 2.50  THEN '✅ Garder — Rentable'
        WHEN "cout_par_heure" < 5.00  THEN '🟡 À surveiller'
        ELSE                               '🔴 Résilier — Trop cher'
    END                 AS "Recommandation"
FROM "bilan_complet"
ORDER BY "cout_par_heure" ASC NULLS LAST;
