-- ============================================================
--  BASE DE DONNÉES : GROUPE GTA
--  Système de gestion d'encadrement scolaire
--  Version : 1.0 — Architecte : Claude / CéJay
-- ============================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET FOREIGN_KEY_CHECKS = 0;
SET time_zone = "+00:00";
SET NAMES utf8mb4;

-- ============================================================
-- BASE
-- ============================================================
CREATE DATABASE IF NOT EXISTS `groupe_gta`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE `groupe_gta`;

-- ============================================================
-- TABLE : roles
-- Rôles système : admin, parent, prof, eleve, staff
-- ============================================================
CREATE TABLE IF NOT EXISTS `roles` (
    `id`          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nom`         VARCHAR(30)      NOT NULL UNIQUE,
    `libelle`     VARCHAR(60)      NOT NULL,
    `niveau`      TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1=élève, 5=admin absolu',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `roles` (`nom`, `libelle`, `niveau`) VALUES
    ('admin',   'Administrateur Absolu',    5),
    ('parent',  'Admin Secondaire / Père',  4),
    ('prof',    'Professeur',               3),
    ('staff',   'Personnel Staff',          2),
    ('eleve',   'Élève',                    1);

-- ============================================================
-- TABLE : utilisateurs
-- Tous les comptes (admins, profs, élèves, staff)
-- ============================================================
CREATE TABLE IF NOT EXISTS `utilisateurs` (
    `id`                INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    `role_id`           TINYINT UNSIGNED    NOT NULL,
    `username`          VARCHAR(50)         NOT NULL UNIQUE,
    `mot_de_passe`      VARCHAR(255)        NOT NULL COMMENT 'Mot de passe haché (bcrypt)',
    `nom_complet`       VARCHAR(120)        NOT NULL,
    `email`             VARCHAR(120)        DEFAULT NULL UNIQUE,
    `telephone`         VARCHAR(20)         DEFAULT NULL,
    `avatar_url`        VARCHAR(500)        DEFAULT NULL,
    `bio`               TEXT                DEFAULT NULL,
    `actif`             TINYINT(1)          NOT NULL DEFAULT 1,
    `derniere_connexion` DATETIME           DEFAULT NULL,
    `created_at`        DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_username`  (`username`),
    KEY `idx_role_id`   (`role_id`),
    KEY `idx_actif`     (`actif`),
    CONSTRAINT `fk_utilisateurs_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comptes par défaut (mots de passe à hacher en production avec bcrypt)
INSERT INTO `utilisateurs` (`role_id`, `username`, `mot_de_passe`, `nom_complet`, `email`, `telephone`) VALUES
    (1, 'ceejay',  '$2b$12$PLACEHOLDER_HASH_ceejay',  'CEEJAY — Maître Absolu', 'ceejay@gta.ci',  '+22501730455'),
    (2, 'lepere',  '$2b$12$PLACEHOLDER_HASH_lepere',  'Le Père — Admin GTA',    'lepere@gta.ci',  '+22501730455');

-- ============================================================
-- TABLE : sessions
-- Gestion des sessions actives (sécurité)
-- ============================================================
CREATE TABLE IF NOT EXISTS `sessions` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `utilisateur_id` INT UNSIGNED   NOT NULL,
    `token`         CHAR(64)        NOT NULL UNIQUE COMMENT 'Token aléatoire SHA256',
    `ip`            VARCHAR(45)     DEFAULT NULL,
    `user_agent`    VARCHAR(255)    DEFAULT NULL,
    `expire_a`      DATETIME        NOT NULL,
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_token`         (`token`),
    KEY `idx_utilisateur`   (`utilisateur_id`),
    CONSTRAINT `fk_sessions_user` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : classes
-- Niveaux scolaires
-- ============================================================
CREATE TABLE IF NOT EXISTS `classes` (
    `id`        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nom`       VARCHAR(60)       NOT NULL UNIQUE,
    `niveau`    VARCHAR(30)       DEFAULT NULL COMMENT 'Ex: Seconde, Première, Terminale',
    `annee`     YEAR              NOT NULL DEFAULT (YEAR(CURDATE())),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `classes` (`nom`, `niveau`) VALUES
    ('Seconde A', 'Seconde'), ('Seconde C', 'Seconde'), ('Seconde D', 'Seconde'),
    ('Première A', 'Première'), ('Première C', 'Première'), ('Première D', 'Première'),
    ('Terminale A', 'Terminale'), ('Terminale C', 'Terminale'), ('Terminale D', 'Terminale'),
    ('3ème', 'Collège'), ('4ème', 'Collège');

-- ============================================================
-- TABLE : eleves
-- Profil étendu des élèves (lié à utilisateurs)
-- ============================================================
CREATE TABLE IF NOT EXISTS `eleves` (
    `id`            INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    `utilisateur_id` INT UNSIGNED       NOT NULL UNIQUE,
    `classe_id`     SMALLINT UNSIGNED   DEFAULT NULL,
    `matricule`     VARCHAR(20)         DEFAULT NULL UNIQUE,
    `date_naissance` DATE               DEFAULT NULL,
    `parents_contact` VARCHAR(200)      DEFAULT NULL,
    `notes_admin`   TEXT                DEFAULT NULL,
    `statut`        ENUM('actif','suspendu','diplômé','sorti') NOT NULL DEFAULT 'actif',
    `created_at`    DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_classe_id` (`classe_id`),
    CONSTRAINT `fk_eleves_user`   FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_eleves_classe` FOREIGN KEY (`classe_id`)      REFERENCES `classes` (`id`) ON SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : profs
-- Profil étendu des professeurs
-- ============================================================
CREATE TABLE IF NOT EXISTS `profs` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `utilisateur_id` INT UNSIGNED  NOT NULL UNIQUE,
    `specialite`    VARCHAR(100)    DEFAULT NULL,
    `diplome`       VARCHAR(200)    DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_profs_user` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : inscriptions_telegram
-- Données soumises via le formulaire d'inscription (Telegram)
-- ============================================================
CREATE TABLE IF NOT EXISTS `inscriptions_telegram` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `prenom`        VARCHAR(80)     NOT NULL,
    `nom`           VARCHAR(80)     NOT NULL,
    `classe_voulue` VARCHAR(60)     DEFAULT NULL,
    `telephone`     VARCHAR(20)     NOT NULL,
    `email`         VARCHAR(120)    DEFAULT NULL,
    `message`       TEXT            DEFAULT NULL,
    `telegram_ok`   TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Confirmation envoi Telegram',
    `traite`        TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Traité par admin',
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_traite` (`traite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : documents
-- Fichiers uploadés par les utilisateurs
-- ============================================================
CREATE TABLE IF NOT EXISTS `documents` (
    `id`                INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `proprietaire_id`   INT UNSIGNED    NOT NULL COMMENT 'Utilisateur qui a uploadé',
    `partage_avec_id`   INT UNSIGNED    DEFAULT NULL COMMENT 'Destinataire (null = visible de tous selon rôle)',
    `nom_fichier`       VARCHAR(255)    NOT NULL,
    `nom_original`      VARCHAR(255)    NOT NULL,
    `type_mime`         VARCHAR(100)    DEFAULT NULL,
    `taille`            BIGINT UNSIGNED DEFAULT NULL COMMENT 'Taille en octets',
    `chemin`            VARCHAR(500)    NOT NULL COMMENT 'Chemin serveur ou URL objet-storage',
    `categorie`         ENUM('cours','devoir','resultat','admin','autre') NOT NULL DEFAULT 'autre',
    `description`       VARCHAR(300)    DEFAULT NULL,
    `classe_id`         SMALLINT UNSIGNED DEFAULT NULL,
    `telechargements`   INT UNSIGNED    NOT NULL DEFAULT 0,
    `created_at`        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_proprietaire`  (`proprietaire_id`),
    KEY `idx_partage`       (`partage_avec_id`),
    KEY `idx_categorie`     (`categorie`),
    CONSTRAINT `fk_docs_proprio`  FOREIGN KEY (`proprietaire_id`)  REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_docs_partage`  FOREIGN KEY (`partage_avec_id`)  REFERENCES `utilisateurs` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_docs_classe`   FOREIGN KEY (`classe_id`)        REFERENCES `classes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : competences
-- Compétences suivies par élève
-- ============================================================
CREATE TABLE IF NOT EXISTS `competences` (
    `id`        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `nom`       VARCHAR(120)    NOT NULL,
    `categorie` VARCHAR(80)     DEFAULT NULL COMMENT 'Ex: Mathématiques, Français, Sciences',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : suivi_competences
-- Note et progression d'un élève sur une compétence
-- ============================================================
CREATE TABLE IF NOT EXISTS `suivi_competences` (
    `id`            INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    `eleve_id`      INT UNSIGNED        NOT NULL,
    `competence_id` INT UNSIGNED        NOT NULL,
    `evaluateur_id` INT UNSIGNED        NOT NULL COMMENT 'Prof ou admin qui a évalué',
    `note`          DECIMAL(5,2)        DEFAULT NULL COMMENT 'Note sur 20',
    `niveau`        ENUM('débutant','intermédiaire','avancé','maîtrisé') DEFAULT NULL,
    `commentaire`   TEXT                DEFAULT NULL,
    `date_eval`     DATE                NOT NULL DEFAULT (CURDATE()),
    `created_at`    DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_eleve`      (`eleve_id`),
    KEY `idx_competence` (`competence_id`),
    CONSTRAINT `fk_sc_eleve`      FOREIGN KEY (`eleve_id`)      REFERENCES `eleves` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sc_competence` FOREIGN KEY (`competence_id`) REFERENCES `competences` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sc_evaluateur` FOREIGN KEY (`evaluateur_id`) REFERENCES `utilisateurs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : notifications
-- Notifications système (cloche) pour chaque utilisateur
-- ============================================================
CREATE TABLE IF NOT EXISTS `notifications` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `destinataire_id` INT UNSIGNED  NOT NULL,
    `titre`         VARCHAR(120)    NOT NULL,
    `message`       TEXT            NOT NULL,
    `type`          ENUM('info','success','warning','error') NOT NULL DEFAULT 'info',
    `lue`           TINYINT(1)      NOT NULL DEFAULT 0,
    `lien`          VARCHAR(300)    DEFAULT NULL COMMENT 'URL de redirection au clic',
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_destinataire`  (`destinataire_id`),
    KEY `idx_lue`           (`lue`),
    CONSTRAINT `fk_notif_user` FOREIGN KEY (`destinataire_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : journal_activites
-- Historique complet de toutes les actions (audit log)
-- ============================================================
CREATE TABLE IF NOT EXISTS `journal_activites` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `utilisateur_id` INT UNSIGNED   DEFAULT NULL,
    `action`        VARCHAR(100)    NOT NULL COMMENT 'Ex: login, create_user, upload_doc',
    `description`   TEXT            DEFAULT NULL,
    `ip`            VARCHAR(45)     DEFAULT NULL,
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_id`   (`utilisateur_id`),
    KEY `idx_action`    (`action`),
    KEY `idx_date`      (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : messages_internes
-- Messagerie interne entre utilisateurs
-- ============================================================
CREATE TABLE IF NOT EXISTS `messages_internes` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `expediteur_id` INT UNSIGNED    NOT NULL,
    `destinataire_id` INT UNSIGNED  NOT NULL,
    `sujet`         VARCHAR(200)    DEFAULT NULL,
    `contenu`       TEXT            NOT NULL,
    `lu`            TINYINT(1)      NOT NULL DEFAULT 0,
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_expediteur`    (`expediteur_id`),
    KEY `idx_destinataire`  (`destinataire_id`),
    CONSTRAINT `fk_msg_exp`  FOREIGN KEY (`expediteur_id`)   REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_msg_dest` FOREIGN KEY (`destinataire_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE : parametres_systeme
-- Paramètres globaux de l'application (admin only)
-- ============================================================
CREATE TABLE IF NOT EXISTS `parametres_systeme` (
    `cle`       VARCHAR(80)     NOT NULL,
    `valeur`    TEXT            DEFAULT NULL,
    `updated_at` DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`cle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `parametres_systeme` (`cle`, `valeur`) VALUES
    ('nom_structure', 'Groupe GTA'),
    ('telephone_admin', '0173045519'),
    ('telegram_bot_token', '8672835698:AAE5XG2wSh8DSTWAc32ncYhf-WR-eMJ_yNk'),
    ('telegram_chat_id', ''),
    ('maintenance_mode', '0'),
    ('max_upload_mo', '10');

-- ============================================================
-- VUES UTILES (performance + lisibilité)
-- ============================================================

-- Vue : liste complète des utilisateurs avec leur rôle
CREATE OR REPLACE VIEW `vue_utilisateurs` AS
SELECT
    u.id,
    r.nom          AS role,
    r.libelle      AS role_libelle,
    r.niveau       AS role_niveau,
    u.username,
    u.nom_complet,
    u.email,
    u.telephone,
    u.actif,
    u.derniere_connexion,
    u.created_at
FROM `utilisateurs` u
JOIN `roles` r ON u.role_id = r.id;

-- Vue : statistiques globales (pour le dashboard admin)
CREATE OR REPLACE VIEW `vue_stats_globales` AS
SELECT
    (SELECT COUNT(*) FROM utilisateurs WHERE actif = 1)                             AS total_utilisateurs_actifs,
    (SELECT COUNT(*) FROM utilisateurs u JOIN roles r ON u.role_id = r.id WHERE r.nom = 'eleve' AND u.actif = 1)  AS total_eleves,
    (SELECT COUNT(*) FROM utilisateurs u JOIN roles r ON u.role_id = r.id WHERE r.nom = 'prof' AND u.actif = 1)   AS total_profs,
    (SELECT COUNT(*) FROM documents)                                                AS total_documents,
    (SELECT COUNT(*) FROM inscriptions_telegram WHERE traite = 0)                  AS inscriptions_en_attente,
    (SELECT COUNT(*) FROM notifications WHERE lue = 0)                             AS notifications_non_lues;

-- Vue : documents avec infos propriétaire
CREATE OR REPLACE VIEW `vue_documents` AS
SELECT
    d.id,
    d.nom_original,
    d.type_mime,
    d.taille,
    d.categorie,
    d.description,
    d.telechargements,
    d.created_at,
    u.nom_complet  AS uploaded_par,
    r.nom          AS role_uploadeur,
    c.nom          AS classe
FROM `documents` d
JOIN `utilisateurs` u ON d.proprietaire_id = u.id
JOIN `roles` r ON u.role_id = r.id
LEFT JOIN `classes` c ON d.classe_id = c.id;

-- ============================================================
-- INDEX ADDITIONNELS POUR PERFORMANCE
-- ============================================================
CREATE INDEX IF NOT EXISTS `idx_journal_user_date` ON `journal_activites` (`utilisateur_id`, `created_at` DESC);
CREATE INDEX IF NOT EXISTS `idx_notif_dest_lue`    ON `notifications`     (`destinataire_id`, `lue`);

-- ============================================================
-- PROCÉDURE : Créer un utilisateur complet
-- ============================================================
DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS `creer_utilisateur`(
    IN p_role_nom    VARCHAR(30),
    IN p_username    VARCHAR(50),
    IN p_mot_de_passe VARCHAR(255),
    IN p_nom_complet  VARCHAR(120),
    IN p_email        VARCHAR(120),
    IN p_telephone    VARCHAR(20)
)
BEGIN
    DECLARE v_role_id TINYINT UNSIGNED;
    SELECT id INTO v_role_id FROM roles WHERE nom = p_role_nom LIMIT 1;
    IF v_role_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rôle inconnu';
    ELSE
        INSERT INTO utilisateurs (role_id, username, mot_de_passe, nom_complet, email, telephone)
        VALUES (v_role_id, p_username, p_mot_de_passe, p_nom_complet, p_email, p_telephone);
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- PROCÉDURE : Enregistrer une connexion (session + journal)
-- ============================================================
DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS `enregistrer_connexion`(
    IN p_user_id    INT UNSIGNED,
    IN p_token      CHAR(64),
    IN p_ip         VARCHAR(45),
    IN p_user_agent VARCHAR(255)
)
BEGIN
    -- Enregistre la session (expire dans 8h)
    INSERT INTO sessions (utilisateur_id, token, ip, user_agent, expire_a)
    VALUES (p_user_id, p_token, p_ip, p_user_agent, DATE_ADD(NOW(), INTERVAL 8 HOUR));

    -- Met à jour la dernière connexion
    UPDATE utilisateurs SET derniere_connexion = NOW() WHERE id = p_user_id;

    -- Journal
    INSERT INTO journal_activites (utilisateur_id, action, ip)
    VALUES (p_user_id, 'login', p_ip);
END$$
DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- FIN DU SCRIPT — GROUPE GTA DATABASE v1.0
-- ============================================================
