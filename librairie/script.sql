-- =====================================================
-- Projet : Gestion d'une librairie
-- SGBD   : MySQL / MariaDB
-- =====================================================

DROP DATABASE IF EXISTS librairie;
CREATE DATABASE librairie CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE librairie;

-- ---------- 1. CREATION DES TABLES ----------

CREATE TABLE client (
    id_client   INT AUTO_INCREMENT PRIMARY KEY,
    nom         VARCHAR(50)  NOT NULL,
    prenom      VARCHAR(50)  NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    telephone   VARCHAR(20),
    ville       VARCHAR(50)
);

CREATE TABLE auteur (
    id_auteur    INT AUTO_INCREMENT PRIMARY KEY,
    nom          VARCHAR(50) NOT NULL,
    prenom       VARCHAR(50) NOT NULL,
    nationalite  VARCHAR(50)
);

CREATE TABLE livre (
    id_livre         INT AUTO_INCREMENT PRIMARY KEY,
    titre            VARCHAR(150) NOT NULL,
    isbn             VARCHAR(20)  NOT NULL UNIQUE,
    prix             DECIMAL(8,2) NOT NULL CHECK (prix >= 0),
    stock            INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    annee_publication YEAR
);

CREATE TABLE commande (
    id_commande    INT AUTO_INCREMENT PRIMARY KEY,
    date_commande  DATE NOT NULL,
    statut         VARCHAR(20) NOT NULL DEFAULT 'en cours',
    id_client      INT NOT NULL,
    FOREIGN KEY (id_client) REFERENCES client(id_client)
);

-- Association N-N : un livre peut avoir plusieurs auteurs
CREATE TABLE ecrire (
    id_auteur INT NOT NULL,
    id_livre  INT NOT NULL,
    PRIMARY KEY (id_auteur, id_livre),
    FOREIGN KEY (id_auteur) REFERENCES auteur(id_auteur),
    FOREIGN KEY (id_livre)  REFERENCES livre(id_livre)
);

-- Association N-N avec attributs : lignes d'une commande
CREATE TABLE contenir (
    id_commande   INT NOT NULL,
    id_livre      INT NOT NULL,
    quantite      INT NOT NULL CHECK (quantite > 0),
    prix_unitaire DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (id_commande, id_livre),
    FOREIGN KEY (id_commande) REFERENCES commande(id_commande),
    FOREIGN KEY (id_livre)    REFERENCES livre(id_livre)
);

-- ---------- 2. DONNEES D'EXEMPLE ----------

INSERT INTO client (nom, prenom, email, telephone, ville) VALUES
('Benali',  'Youssef', 'youssef.benali@mail.com', '0600000001', 'Marrakech'),
('Alaoui',  'Sara',    'sara.alaoui@mail.com',    '0600000002', 'Casablanca'),
('Idrissi', 'Omar',    'omar.idrissi@mail.com',   '0600000003', 'Rabat'),
('Tazi',    'Lina',    'lina.tazi@mail.com',      '0600000004', 'Marrakech');

INSERT INTO auteur (nom, prenom, nationalite) VALUES
('Hugo',      'Victor',   'Française'),
('Camus',     'Albert',   'Française'),
('Ben Jelloun','Tahar',   'Marocaine'),
('Choukri',   'Mohamed',  'Marocaine'),
('Saint-Exupéry','Antoine','Française');

INSERT INTO livre (titre, isbn, prix, stock, annee_publication) VALUES
('Les Misérables',      '978-2-07-040850-4', 12.50, 20, 1862),
('L''Étranger',         '978-2-07-036002-1',  7.90, 35, 1942),
('La Nuit sacrée',      '978-2-02-009862-3',  9.50, 12, 1987),
('Le Pain nu',          '978-2-70-710123-6',  8.00,  5, 1973),
('Le Petit Prince',     '978-2-07-040850-9',  6.50, 50, 1943),
('La Peste',            '978-2-07-036042-7',  8.50,  0, 1947);

INSERT INTO ecrire (id_auteur, id_livre) VALUES
(1,1), (2,2), (2,6), (3,3), (4,4), (5,5);

INSERT INTO commande (date_commande, statut, id_client) VALUES
('2026-09-01', 'livrée',   1),
('2026-09-05', 'livrée',   2),
('2026-09-12', 'en cours', 1),
('2026-09-20', 'livrée',   3),
('2026-10-02', 'en cours', 4);

INSERT INTO contenir (id_commande, id_livre, quantite, prix_unitaire) VALUES
(1, 1, 1, 12.50),
(1, 5, 2,  6.50),
(2, 2, 1,  7.90),
(2, 3, 1,  9.50),
(3, 5, 3,  6.50),
(4, 4, 2,  8.00),
(4, 1, 1, 12.50),
(5, 2, 2,  7.90);

-- ---------- 3. REQUETES ----------

-- Q1 : Liste des livres avec leur(s) auteur(s)  (jointure)
SELECT l.titre, CONCAT(a.prenom, ' ', a.nom) AS auteur, l.prix
FROM livre l
JOIN ecrire e ON e.id_livre = l.id_livre
JOIN auteur a ON a.id_auteur = e.id_auteur
ORDER BY l.titre;

-- Q2 : Montant total de chaque commande  (SUM + GROUP BY)
SELECT c.id_commande, c.date_commande,
       SUM(ct.quantite * ct.prix_unitaire) AS total
FROM commande c
JOIN contenir ct ON ct.id_commande = c.id_commande
GROUP BY c.id_commande, c.date_commande;

-- Q3 : Chiffre d'affaires par client, du plus gros au plus petit
SELECT cl.nom, cl.prenom,
       SUM(ct.quantite * ct.prix_unitaire) AS total_depense
FROM client cl
JOIN commande c   ON c.id_client = cl.id_client
JOIN contenir ct  ON ct.id_commande = c.id_commande
GROUP BY cl.id_client, cl.nom, cl.prenom
ORDER BY total_depense DESC;

-- Q4 : Top 3 des livres les plus vendus
SELECT l.titre, SUM(ct.quantite) AS quantite_vendue
FROM livre l
JOIN contenir ct ON ct.id_livre = l.id_livre
GROUP BY l.id_livre, l.titre
ORDER BY quantite_vendue DESC
LIMIT 3;

-- Q5 : Livres à réapprovisionner (stock <= 5)
SELECT titre, stock
FROM livre
WHERE stock <= 5
ORDER BY stock;
