-- ============================================================
-- StreamTrack — seed.sql (version corrigée)
-- Aucun ID en dur dans watch_history : tout passe par des
-- sous-requêtes sur les titres et usernames.
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. PLATFORMS
-- ============================================================
INSERT INTO "platforms" ("name", "monthly_price", "currency", "subscription_start")
VALUES
    ('Netflix',      5.99,  'EUR', '2023-06-01'),
    ('Disney+',      8.99,  'EUR', '2023-11-01'),
    ('Prime Video',  6.99,  'EUR', '2022-03-15'),
    ('Apple TV+',    9.99,  'EUR', '2024-01-10');

-- ============================================================
-- 2. USERS
-- ============================================================
INSERT INTO "users" ("username", "email", "created_at")
VALUES
    ('Alice', 'alice@email.com', '2023-06-01 10:00:00'),
    ('Tom',   NULL,              '2023-11-01 18:30:00');

-- ============================================================
-- 3. CONTENTS — Films
-- ============================================================
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "release_year")
VALUES
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'),      NULL, 'Oppenheimer',               'movie', 180, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'),      NULL, 'Rebel Moon',                'movie', 135, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'),      NULL, 'Le Monde après nous',       'movie', 138, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Disney+'),      NULL, 'Wish',                      'movie', 95,  2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Disney+'),      NULL, 'Indiana Jones 5',           'movie', 154, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Prime Video'),  NULL, 'Saltburn',                  'movie', 131, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Prime Video'),  NULL, 'The Holdovers',             'movie', 133, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Apple TV+'),    NULL, 'Napoleon',                  'movie', 158, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Apple TV+'),    NULL, 'Killers of the Flower Moon','movie', 206, 2023);

-- ============================================================
-- 3. CONTENTS — Séries
-- ============================================================
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "release_year")
VALUES
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'),     NULL, 'The Crown',      'series', NULL, 2016),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'),     NULL, 'Squid Game',     'series', NULL, 2021),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Disney+'),     NULL, 'Loki',           'series', NULL, 2021),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Prime Video'), NULL, 'Rings of Power', 'series', NULL, 2022),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Apple TV+'),   NULL, 'Ted Lasso',      'series', NULL, 2020);

-- ============================================================
-- 3. CONTENTS — Épisodes (parent_id via sous-requête)
-- ============================================================

-- The Crown S6
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "season", "episode", "release_year")
VALUES
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'), (SELECT "id" FROM "contents" WHERE "title" = 'The Crown'), 'The Crown S6E1', 'episode', 56, 6, 1, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'), (SELECT "id" FROM "contents" WHERE "title" = 'The Crown'), 'The Crown S6E2', 'episode', 54, 6, 2, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'), (SELECT "id" FROM "contents" WHERE "title" = 'The Crown'), 'The Crown S6E3', 'episode', 57, 6, 3, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'), (SELECT "id" FROM "contents" WHERE "title" = 'The Crown'), 'The Crown S6E4', 'episode', 52, 6, 4, 2023);

-- Squid Game S1
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "season", "episode", "release_year")
VALUES
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'), (SELECT "id" FROM "contents" WHERE "title" = 'Squid Game'), 'Squid Game S1E1', 'episode', 60, 1, 1, 2021),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'), (SELECT "id" FROM "contents" WHERE "title" = 'Squid Game'), 'Squid Game S1E2', 'episode', 63, 1, 2, 2021),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Netflix'), (SELECT "id" FROM "contents" WHERE "title" = 'Squid Game'), 'Squid Game S1E3', 'episode', 56, 1, 3, 2021);

-- Loki S2
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "season", "episode", "release_year")
VALUES
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Disney+'), (SELECT "id" FROM "contents" WHERE "title" = 'Loki'), 'Loki S2E1', 'episode', 48, 2, 1, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Disney+'), (SELECT "id" FROM "contents" WHERE "title" = 'Loki'), 'Loki S2E2', 'episode', 44, 2, 2, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Disney+'), (SELECT "id" FROM "contents" WHERE "title" = 'Loki'), 'Loki S2E3', 'episode', 46, 2, 3, 2023);

-- Rings of Power S1
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "season", "episode", "release_year")
VALUES
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Prime Video'), (SELECT "id" FROM "contents" WHERE "title" = 'Rings of Power'), 'Rings of Power S1E1', 'episode', 71, 1, 1, 2022),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Prime Video'), (SELECT "id" FROM "contents" WHERE "title" = 'Rings of Power'), 'Rings of Power S1E2', 'episode', 68, 1, 2, 2022);

-- Ted Lasso S3
INSERT INTO "contents" ("platform_id", "parent_id", "title", "type", "duration_min", "season", "episode", "release_year")
VALUES
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Apple TV+'), (SELECT "id" FROM "contents" WHERE "title" = 'Ted Lasso'), 'Ted Lasso S3E1', 'episode', 43, 3, 1, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Apple TV+'), (SELECT "id" FROM "contents" WHERE "title" = 'Ted Lasso'), 'Ted Lasso S3E2', 'episode', 46, 3, 2, 2023),
    ((SELECT "id" FROM "platforms" WHERE "name" = 'Apple TV+'), (SELECT "id" FROM "contents" WHERE "title" = 'Ted Lasso'), 'Ted Lasso S3E3', 'episode', 44, 3, 3, 2023);

-- ============================================================
-- 4. WATCH_HISTORY — 100% sous-requêtes, zéro ID en dur
-- ============================================================

-- JANVIER 2024 — Alice

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Oppenheimer'), '2024-01-05 20:30:00', 90, 0);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Oppenheimer'), '2024-01-06 20:00:00', 90, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'The Crown S6E1'), '2024-01-08 21:00:00', 56, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'The Crown S6E2'), '2024-01-09 21:00:00', 54, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'The Crown S6E3'), '2024-01-10 21:00:00', 57, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'The Crown S6E4'), '2024-01-11 21:00:00', 52, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Killers of the Flower Moon'), '2024-01-14 18:00:00', 206, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Ted Lasso S3E1'), '2024-01-20 22:00:00', 43, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Ted Lasso S3E2'), '2024-01-21 22:00:00', 46, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Ted Lasso S3E3'), '2024-01-22 22:00:00', 44, 1);

-- JANVIER 2024 — Tom

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Wish'), '2024-01-06 16:00:00', 95, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Squid Game S1E1'), '2024-01-13 20:00:00', 60, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Squid Game S1E2'), '2024-01-14 20:00:00', 63, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Squid Game S1E3'), '2024-01-15 20:00:00', 56, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Loki S2E1'), '2024-01-20 19:00:00', 48, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Loki S2E2'), '2024-01-21 19:00:00', 44, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Loki S2E3'), '2024-01-22 19:00:00', 20, 0);

-- FÉVRIER 2024 — Alice

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Saltburn'), '2024-02-03 21:00:00', 131, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Rebel Moon'), '2024-02-10 20:00:00', 70, 0);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Napoleon'), '2024-02-17 19:30:00', 158, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Rings of Power S1E1'), '2024-02-24 21:00:00', 71, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Rings of Power S1E2'), '2024-02-25 21:00:00', 68, 1);

-- FÉVRIER 2024 — Tom

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Indiana Jones 5'), '2024-02-04 15:00:00', 154, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Le Monde après nous'), '2024-02-11 20:30:00', 138, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'The Holdovers'), '2024-02-18 20:00:00', 133, 1);

-- MARS 2024 — Alice

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Ted Lasso S3E1'), '2024-03-02 22:00:00', 43, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Ted Lasso S3E2'), '2024-03-03 22:00:00', 46, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Alice'), (SELECT "id" FROM "contents" WHERE "title" = 'Killers of the Flower Moon'), '2024-03-10 17:00:00', 206, 1);

-- MARS 2024 — Tom

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Rings of Power S1E1'), '2024-03-05 20:00:00', 71, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Loki S2E3'), '2024-03-12 19:30:00', 46, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Squid Game S1E1'), '2024-03-20 21:00:00', 60, 1);

INSERT INTO "watch_history" ("user_id", "content_id", "watched_at", "watched_duration_min", "completed")
VALUES ((SELECT "id" FROM "users" WHERE "username" = 'Tom'), (SELECT "id" FROM "contents" WHERE "title" = 'Squid Game S1E2'), '2024-03-21 21:00:00', 63, 1);
