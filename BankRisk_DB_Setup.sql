-- ============================================================
-- PROJEKT: Automatizovaný monitoring rizikovosti portfolia
-- SOUBOR:  BankRisk_DB_Setup.sql
-- AUTOR:   Rudolf Munzig
-- VERZE:   1.0 | 2025
-- POPIS:   Vytvoření databáze BankRisk_DB, tabulek a View
--          pro analýzu retailových úvěrových rizik.
-- ============================================================


-- ==============================================================
-- KROK 1: VYTVOŘENÍ DATABÁZE
-- ==============================================================

-- Pokud databáze již existuje, bezpečně ji smažeme a vytvoříme znovu
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BankRisk_DB')
BEGIN
    -- Zavřeme aktivní spojení před mazáním
    ALTER DATABASE BankRisk_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankRisk_DB;
END
GO

CREATE DATABASE BankRisk_DB
    COLLATE Czech_CI_AS; -- Nastavení české řazení (podpora háčků a čárek)
GO

USE BankRisk_DB;
GO


-- ==============================================================
-- KROK 2: DIMENZIONÁLNÍ TABULKA KLIENTŮ (DimClients)
-- ==============================================================
-- Obsahuje demografické a identifikační informace o klientech.

CREATE TABLE DimClients (
    ClientID        INT           PRIMARY KEY,        -- Unikátní identifikátor klienta
    Jmeno           NVARCHAR(100) NOT NULL,            -- Celé jméno klienta (česky)
    DatumNarozeni   DATE          NOT NULL,            -- Datum narození
    Mesto           NVARCHAR(100) NOT NULL,            -- Město bydliště
    Zamestnani      NVARCHAR(100) NOT NULL,            -- Pracovní pozice / zaměstnání
    MesicniPrijem   DECIMAL(12,2) NOT NULL,            -- Čistý měsíční příjem v CZK
    KreditniSkore   INT           NOT NULL,            -- Interní kreditní skóre (300–850)
    SegmentKlienta  NVARCHAR(50)  NOT NULL             -- Zákaznický segment (Retail, Premium, atd.)
);
GO

-- Vložení 25 realistických českých klientů
-- POZNÁMKA: Klienti č. 24 a 25 jsou záměrné OUTLIERY s extrémní rizikovostí
INSERT INTO DimClients VALUES
(1,  N'Tomáš Novák',        '1985-03-12', N'Praha',       N'IT specialista',        52000.00, 720, N'Retail'),
(2,  N'Jana Svobodová',     '1990-07-24', N'Brno',        N'Účetní',                41000.00, 695, N'Retail'),
(3,  N'Petr Dvořák',        '1978-11-05', N'Ostrava',     N'Strojní inženýr',       58000.00, 745, N'Premium'),
(4,  N'Lucie Procházková',  '1993-02-18', N'Plzeň',       N'Marketingový manažer',  47000.00, 710, N'Retail'),
(5,  N'Martin Krejčí',      '1982-09-30', N'Olomouc',     N'Obchodní zástupce',     39000.00, 680, N'Retail'),
(6,  N'Eva Horáková',       '1975-05-14', N'Liberec',     N'Ředitelka školy',       62000.00, 780, N'Premium'),
(7,  N'Jan Pospíšil',       '1988-08-22', N'České Budějovice', N'Řidič kamionu',    35000.00, 640, N'Retail'),
(8,  N'Monika Blažková',    '1995-01-07', N'Hradec Králové', N'Zdravotní sestra',   32000.00, 620, N'Retail'),
(9,  N'Ondřej Marešek',     '1980-12-16', N'Pardubice',   N'Konstruktér',           54000.00, 730, N'Premium'),
(10, N'Tereza Nováčková',   '1992-04-03', N'Zlín',        N'Grafická designérka',   38000.00, 665, N'Retail'),
(11, N'Vladimír Hájek',     '1970-06-29', N'Jihlava',     N'Starosta obce',         48000.00, 700, N'Retail'),
(12, N'Petra Kratochvílová', '1987-10-11', N'Teplice',    N'Farmaceut',             55000.00, 740, N'Premium'),
(13, N'Jakub Říha',         '1999-03-25', N'Most',        N'Junior developer',      28000.00, 600, N'Retail'),
(14, N'Simona Kopecká',     '1983-07-17', N'Kladno',      N'Personalistka',         43000.00, 690, N'Retail'),
(15, N'Radek Beneš',        '1976-01-08', N'Mladá Boleslav', N'Technolog Škoda',    60000.00, 755, N'Premium'),
(16, N'Zuzana Poláková',    '1991-05-20', N'Opava',       N'Laborantka',            33000.00, 625, N'Retail'),
(17, N'Michal Sedláček',    '1984-09-14', N'Frýdek-Místek', N'Svářeč',             31000.00, 595, N'Retail'),
(18, N'Barbora Urban',      '1997-12-01', N'Havířov',     N'Recepční',              25000.00, 580, N'Retail'),
(19, N'Lukáš Marek',        '1979-08-07', N'Přerov',      N'Provozní manažer',      57000.00, 735, N'Premium'),
(20, N'Renata Šimková',     '1986-02-23', N'Ústí nad Labem', N'Sociální pracovnice', 29000.00, 605, N'Retail'),
(21, N'Zdeněk Fiala',       '1973-11-19', N'Karviná',     N'Horník',                36000.00, 645, N'Retail'),
(22, N'Alena Marková',      '1989-04-30', N'Chomutov',    N'Učitelka',              34000.00, 650, N'Retail'),
(23, N'Stanislav Vorel',    '1968-07-12', N'Znojmo',      N'Zemědělec',             27000.00, 570, N'Retail'),
-- *** OUTLIER #1 – Extrémní výše dluhu + prodlení přes 120 dní ***
(24, N'Igor Švarc',         '1965-03-03', N'Praha',       N'Nezaměstnaný',          8000.00,  310, N'High Risk'),
-- *** OUTLIER #2 – Extrémní výše dluhu + prodlení přes 120 dní ***
(25, N'Dagmar Blahutová',   '1972-09-09', N'Ostrava',     N'Nezaměstnaná',          6500.00,  290, N'High Risk');
GO


-- ==============================================================
-- KROK 3: DIMENZIONÁLNÍ TABULKA PRODUKTŮ (DimProducts)
-- ==============================================================
-- Katalog úvěrových produktů banky.

CREATE TABLE DimProducts (
    ProductID       INT           PRIMARY KEY,        -- Unikátní ID produktu
    NazevProduktu   NVARCHAR(100) NOT NULL,            -- Název úvěrového produktu
    TypProduktu     NVARCHAR(50)  NOT NULL,            -- Typ: Hypotéka, Spotřebitel, Revolvingový
    UrokovaSazba    DECIMAL(5,2)  NOT NULL,            -- Roční úroková sazba v %
    MaxVyseUveru    DECIMAL(15,2) NOT NULL,            -- Maximální výše úvěru v CZK
    MinDoba         INT           NOT NULL,            -- Minimální splatnost v měsících
    MaxDoba         INT           NOT NULL             -- Maximální splatnost v měsících
);
GO

INSERT INTO DimProducts VALUES
(1, N'Hypotéka Klasik',           N'Hypoteční úvěr',      3.49,  10000000.00, 60,  360),
(2, N'Hypotéka Flexi',            N'Hypoteční úvěr',      3.99,   8000000.00, 60,  300),
(3, N'Spotřebitelský úvěr Start', N'Spotřebitelský úvěr', 7.90,    500000.00, 12,   84),
(4, N'Spotřebitelský úvěr Plus',  N'Spotřebitelský úvěr', 9.50,    200000.00, 6,    60),
(5, N'Revolving ČSOB',            N'Revolvingový úvěr',  18.90,    100000.00, 1,    24),
(6, N'Podnikatelský úvěr Mini',   N'Podnikatelský úvěr', 6.50,   2000000.00, 12,  120);
GO


-- ==============================================================
-- KROK 4: FAKTOVÁ TABULKA ÚVĚRŮ (FactLoans)
-- ==============================================================
-- Klíčová tabulka pro rizikovou analýzu – obsahuje stav každého úvěru.

CREATE TABLE FactLoans (
    LoanID          INT           PRIMARY KEY,        -- Unikátní ID úvěru
    ClientID        INT           NOT NULL            -- Reference na klienta
        REFERENCES DimClients(ClientID),
    ProductID       INT           NOT NULL            -- Reference na produkt
        REFERENCES DimProducts(ProductID),
    DatumCerpani    DATE          NOT NULL,            -- Datum čerpání úvěru
    JistinaCZK      DECIMAL(15,2) NOT NULL,            -- Výše jistiny v CZK
    ZbyvatekCZK     DECIMAL(15,2) NOT NULL,            -- Aktuální zůstatek v CZK
    MesicniSplatka  DECIMAL(10,2) NOT NULL,            -- Výše měsíční splátky v CZK
    DPD             INT           NOT NULL,            -- Days Past Due (počet dní v prodlení)
    PocetSplatek    INT           NOT NULL,            -- Celkový počet sjednaných splátek
    ZbyvajiSplatky  INT           NOT NULL,            -- Počet zbývajících splátek
    Kolateral       NVARCHAR(100) NULL,                -- Zajištění úvěru (pokud existuje)
    DatumPosledniSp DATE          NOT NULL             -- Datum poslední splátky
);
GO

-- Vložení 25 úvěrových záznamů
-- Klienti 24 a 25 jsou OUTLIERY s dluhem nad 5 mil. CZK a DPD > 120
INSERT INTO FactLoans VALUES
(101, 1,  1, '2021-04-15',  3500000.00, 3200000.00,  15800.00,  0, 240, 198, N'Byt Praha 5',       '2025-03-01'),
(102, 2,  3, '2022-08-10',    180000.00,  125000.00,   3200.00,  0,  60,  43, NULL,                 '2025-03-05'),
(103, 3,  1, '2019-11-20',  4800000.00, 4100000.00,  21500.00,  5, 300, 253, N'Dům Ostrava-Jih',   '2025-02-25'),
(104, 4,  4, '2023-02-01',    120000.00,   98000.00,   2100.00,  0,  60,  53, NULL,                 '2025-03-10'),
(105, 5,  3, '2022-05-18',    250000.00,  160000.00,   4500.00, 15,  72,  48, NULL,                 '2025-02-15'),
(106, 6,  1, '2018-06-01',  5500000.00, 4200000.00,  24000.00,  0, 360, 280, N'Vila Liberec',      '2025-03-01'),
(107, 7,  4, '2023-09-12',     80000.00,   71000.00,   1800.00, 22,  48,  43, NULL,                 '2025-02-10'),
(108, 8,  5, '2024-01-20',     50000.00,   48000.00,   2500.00, 35,  24,  22, NULL,                 '2025-02-01'),
(109, 9,  2, '2020-03-25',  2900000.00, 2400000.00,  13200.00,  0, 300, 245, N'Byt Pardubice',     '2025-03-08'),
(110, 10, 3, '2023-06-14',    150000.00,  110000.00,   2800.00,  8,  60,  44, NULL,                 '2025-02-20'),
(111, 11, 3, '2022-10-05',    200000.00,  140000.00,   3600.00, 45,  60,  28, NULL,                 '2025-01-20'),
(112, 12, 1, '2020-07-30',  4200000.00, 3600000.00,  18900.00,  0, 300, 238, N'Byt Teplice',       '2025-03-05'),
(113, 13, 5, '2024-06-01',     30000.00,   28500.00,   1500.00, 60,  24,  22, NULL,                 '2025-01-15'),
(114, 14, 4, '2023-01-17',    100000.00,   75000.00,   2200.00,  0,  60,  46, NULL,                 '2025-03-17'),
(115, 15, 1, '2017-08-22',  4900000.00, 3500000.00,  22000.00,  0, 360, 270, N'Dům Mladá Boleslav','2025-03-01'),
(116, 16, 4, '2023-11-03',     70000.00,   60000.00,   1600.00, 28,  48,  40, NULL,                 '2025-02-05'),
(117, 17, 3, '2022-07-27',    130000.00,   95000.00,   2600.00, 90,  60,  33, NULL,                 '2024-12-27'),
(118, 18, 5, '2024-03-11',     25000.00,   23000.00,   1200.00,  0,  24,  22, NULL,                 '2025-03-11'),
(119, 19, 2, '2021-02-14',  3100000.00, 2600000.00,  14500.00,  0, 300, 258, N'Byt Přerov',        '2025-03-01'),
(120, 20, 4, '2023-04-20',     90000.00,   72000.00,   1900.00, 18,  60,  48, NULL,                 '2025-02-18'),
(121, 21, 3, '2022-12-08',    160000.00,  115000.00,   3100.00,  0,  60,  44, NULL,                 '2025-03-08'),
(122, 22, 5, '2024-02-25',     40000.00,   37000.00,   1900.00,  0,  24,  22, NULL,                 '2025-03-05'),
(123, 23, 4, '2023-08-15',     75000.00,   60000.00,   1700.00, 75,  48,  35, NULL,                 '2025-01-08'),
-- *** OUTLIER #1 – Igor Švarc – dluh 6,2 mil. CZK, DPD = 157 dní ***
(124, 24, 1, '2018-01-10',  7200000.00, 6200000.00,  28500.00, 157, 360, 210, N'Dům Praha (exekuce)', '2024-10-25'),
-- *** OUTLIER #2 – Dagmar Blahutová – dluh 5,8 mil. CZK, DPD = 134 dní ***
(125, 25, 2, '2019-05-22',  6900000.00, 5800000.00,  25000.00, 134, 300, 185, N'Byt Ostrava (soudní spor)', '2024-11-15');
GO


-- ==============================================================
-- KROK 5: ANALYTICKÉ VIEW – v_Risk_Report
-- ==============================================================
-- Toto View je srdcem monitoringu. Propojuje všechny tabulky
-- a přiřazuje každému úvěru kategorii rizika dle metodiky Basel III.

CREATE OR ALTER VIEW v_Risk_Report AS
SELECT
    -- Identifikace
    fl.LoanID,
    fl.ClientID,
    dc.Jmeno                        AS KlientJmeno,
    dc.Mesto,
    dc.SegmentKlienta,
    dc.KreditniSkore,

    -- Produktová informace
    dp.NazevProduktu,
    dp.TypProduktu,

    -- Finanční ukazatele
    fl.JistinaCZK,
    fl.ZbyvatekCZK,
    fl.MesicniSplatka,
    fl.DPD,                          -- Days Past Due

    -- Výpočet DTI (Debt-to-Income ratio) – poměr splátky k příjmu
    -- Hodnota nad 40 % je riziková
    CAST(
        (fl.MesicniSplatka / NULLIF(dc.MesicniPrijem, 0)) * 100
    AS DECIMAL(5,1))                AS DTI_Procent,

    -- *** KLÍČOVÁ KLASIFIKACE RIZIKA ***
    -- Logika odpovídá Basel III / ČNB metodice EBA Guidelines
    CASE
        WHEN fl.DPD = 0                 THEN 'Performing'       -- Bez prodlení
        WHEN fl.DPD BETWEEN 1  AND 30   THEN 'Watch List'       -- Sledovaný
        WHEN fl.DPD BETWEEN 31 AND 90   THEN 'Non-Performing'   -- Nesplácený
        WHEN fl.DPD > 90
             AND dc.SegmentKlienta = 'High Risk'
                                        THEN 'High Priority'    -- OUTLIER – prioritní vymáhání
        WHEN fl.DPD > 90                THEN 'Default'          -- Default
    END                             AS RizikovaKategorie,

    -- Datum poslední splátky a výpočet stáří dluhu
    fl.DatumPosledniSp,
    DATEDIFF(DAY, fl.DatumPosledniSp, GETDATE()) AS DniOdPosledniSplatky,

    -- Kolaterál (zajištění)
    ISNULL(fl.Kolateral, N'Bez zajištění') AS Kolateral,

    -- Časová razítka pro audit trail
    GETDATE()                       AS DatumSestaveníReportu

FROM FactLoans      fl
INNER JOIN DimClients  dc ON fl.ClientID  = dc.ClientID
INNER JOIN DimProducts dp ON fl.ProductID = dp.ProductID;
GO

-- ==============================================================
-- OVĚŘENÍ – spusťte pro kontrolu dat
-- ==============================================================
SELECT * FROM v_Risk_Report ORDER BY DPD DESC;
GO

-- Shrnutí počtů dle kategorií
SELECT
    RizikovaKategorie,
    COUNT(*)            AS PocetUveru,
    SUM(ZbyvatekCZK)    AS CelkovyZustatekCZK
FROM v_Risk_Report
GROUP BY RizikovaKategorie
ORDER BY CelkovyZustatekCZK DESC;
GO
