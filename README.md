# BankRisk Portfolio – Monitoring úvěrových rizik

Portfolio projekt vytvořený jako součást přípravy na pozici **Junior analytik úvěrových rizik** v ČSOB.

---

## O projektu

Cílem projektu je ukázat praktické dovednosti v oblasti datové analytiky aplikované na retailové úvěrové portfolio. Projekt simuluje reálný monitoring rizikovosti 25 úvěrů s využitím nástrojů které se běžně používají v bankovním prostředí.
Neustále rozvíjím své znalosti v oblasti datové analytiky a úvěrových rizik. Při tvorbě tohoto projektu jsem spolupracoval s AI nástroji, které mi pomohly překonat technické překážky a posunout výsledek dál než bych dokázal sám. Věřím, že schopnost efektivně využívat dostupné nástroje včetně AI je dnes stejně důležitá dovednost jako samotná technická znalost.

---

## Technologie

| Nástroj | Využití |
|---|---|
| SQL Server 2022 | Databáze, datový model, analytické View |
| Python 3.12 | Automatizovaný export kritických případů |
| Power BI Desktop | Interaktivní dashboard, DirectQuery |
| pandas / pyodbc | Datová manipulace a připojení k DB |

---

## Struktura projektu
```
BankRisk-Portfolio-CSOB/
│
├── BankRisk_DB_Setup.sql             # Vytvoření DB, tabulek, View a dat
├── generate_kriticke_pripady.py      # Python skript pro export CSV
├── Kriticke_pripady_vymahani.csv     # Výstupní soubor s kritickými případy
├── BankRisk_Dashboard.pbix           # Power BI dashboard
└── BankRisk_Technicka_Dokumentace.docx  # Podrobná technická dokumentace
```

---

## Datový model

Databáze **BankRisk_DB** je postavena na hvězdicovém schématu:

- **DimClients** – 25 klientů s českými jmény, městy a příjmy
- **DimProducts** – katalog 6 úvěrových produktů (hypotéky, spotřebitelské úvěry)
- **FactLoans** – 25 úvěrových záznamů včetně DPD (Days Past Due)

---

## Klasifikace rizika

Analytické View `v_Risk_Report` přiřazuje každému úvěru kategorii dle metodiky Basel III:

| Kategorie | DPD | Popis |
|---|---|---|
| Performing | 0 dní | Řádně splácející |
| Watch List | 1–30 dní | Sledovaný |
| Non-Performing | 31–90 dní | Nesplácený |
| Default | 91+ dní | Defaultní |
| **High Priority** | **120+ dní** | **Outlier – okamžitá akce** |

---

## Klíčové výstupy

- 2 identifikované outliery s dluhem nad 5 mil. CZK a DPD přes 120 dní
- Automaticky generovaný CSV soubor pro oddělení vymáhání
- Power BI dashboard se dvěma stránkami – kritické případy a přehled portfolia
- Živé připojení Power BI → SQL Server přes DirectQuery

---

## Jak spustit projekt

1. Spusťte `BankRisk_DB_Setup.sql` v SQL Server Management Studio (F5)
2. Nainstalujte závislosti: `pip install pandas pyodbc`
3. Spusťte Python skript: `python generate_kriticke_pripady.py`
4. Otevřete `BankRisk_Dashboard.pbix` v Power BI Desktop

---

*Rudolf Munzig · 2025*
