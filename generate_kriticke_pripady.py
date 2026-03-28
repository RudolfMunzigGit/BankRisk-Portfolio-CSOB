# ============================================================
# PROJEKT: Automatizovaný monitoring rizikovosti portfolia
# SOUBOR:  generate_kriticke_pripady.py
# AUTOR:   Rudolf Munzig
# VERZE:   1.0 | 2025
# POPIS:   Skript se připojí k BankRisk_DB (SQL Server),
#          načte View v_Risk_Report a exportuje CSV soubor
#          se všemi klienty v kategoriích 'Default' a 'High Priority'.
# ZÁVISLOSTI: pandas, pyodbc  (pip install pandas pyodbc)
# ============================================================

import pandas as pd       # Práce s daty (DataFrame, CSV export)
import pyodbc             # Připojení k SQL Server databázi
import os                 # Práce se soubory a cestami
from datetime import datetime  # Datum a čas pro název souboru


# ==============================================================
# SEKCE 1: KONFIGURACE PŘIPOJENÍ K DATABÁZI
# ==============================================================
# Pro Windows autentifikaci (doporučeno v podnikové síti):
#   Trusted_Connection=yes; → nemusíte zadávat heslo
# Pro SQL Server autentifikaci odkomentujte alternativní řádky

DB_CONFIG = {
    "driver":   "{ODBC Driver 18 for SQL Server}",  # Nainstalovaný ODBC driver
    "server":   "localhost",                          # Název nebo IP SQL Serveru
    "database": "BankRisk_DB",                        # Cílová databáze
    "trusted":  "yes",                                # Windows autentifikace (doporučeno)
    # "uid": "sa",                                   # SQL login – pouze pokud nepoužíváte Windows auth
    # "pwd": "VaseHeslo123",                         # SQL heslo  – NIKDY necommitujte do Gitu!
    "encrypt":  "optional",                           # Šifrování spojení (pro lokální: optional)
    "trust_server_certificate": "yes"                 # Ignoruj self-signed certifikát (dev prostředí)
}

# ==============================================================
# SEKCE 2: NASTAVENÍ VÝSTUPU
# ==============================================================

OUTPUT_DIR      = os.path.dirname(os.path.abspath(__file__))  # Složka skriptu
OUTPUT_FILENAME = "Kriticke_pripady_vymahani.csv"              # Pevný název pro Power BI / archiv
OUTPUT_PATH     = os.path.join(OUTPUT_DIR, OUTPUT_FILENAME)

# Kategorie, které mají být exportovány (Default + speciální flag pro outliery)
RIZIKOVE_KATEGORIE = ("'Default'", "'High Priority'")


# ==============================================================
# SEKCE 3: SQL DOTAZ
# ==============================================================
# Vybíráme pouze kritické případy z analytického View.
# Pořadí: nejdříve High Priority outliery, pak Default dle DPD.

SQL_QUERY = f"""
    SELECT
        LoanID                  AS [ID Uveru],
        ClientID                AS [ID Klienta],
        KlientJmeno             AS [Jmeno klienta],
        Mesto                   AS [Mesto],
        SegmentKlienta          AS [Segment],
        NazevProduktu           AS [Produkt],
        JistinaCZK              AS [Jistina CZK],
        ZbyvatekCZK             AS [Zustatek CZK],
        MesicniSplatka          AS [Mesicni splatka CZK],
        DPD                     AS [DPD - dny v prodleni],
        DTI_Procent             AS [DTI pct],
        KreditniSkore           AS [Kreditni skore],
        RizikovaKategorie       AS [Rizikova kategorie],
        DatumPosledniSp         AS [Datum posledni splatky],
        DniOdPosledniSplatky    AS [Dni od posledni splatky],
        Kolateral               AS [Kolateral],
        DatumSestaveníReportu   AS [Datum sestaveni]
    FROM
        v_Risk_Report
    WHERE
        RizikovaKategorie IN ({', '.join(RIZIKOVE_KATEGORIE)})
    ORDER BY
        -- Outliery (High Priority) vždy první, pak dle DPD sestupně
        CASE WHEN RizikovaKategorie = 'High Priority' THEN 0 ELSE 1 END,
        DPD DESC;
"""


# ==============================================================
# SEKCE 4: FUNKCE PRO PŘIPOJENÍ A EXPORT
# ==============================================================

def build_connection_string(cfg: dict) -> str:
    """Sestaví connection string pro pyodbc z konfiguračního slovníku."""
    return (
        f"DRIVER={cfg['driver']};"
        f"SERVER={cfg['server']};"
        f"DATABASE={cfg['database']};"
        f"Trusted_Connection={cfg['trusted']};"
        f"Encrypt={cfg['encrypt']};"
        f"TrustServerCertificate={cfg['trust_server_certificate']};"
    )


def fetch_risk_data(conn_str: str, query: str) -> pd.DataFrame:
    """
    Připojí se k databázi, spustí SQL dotaz a vrátí DataFrame.

    Args:
        conn_str: Connection string pro pyodbc
        query:    SQL dotaz (SELECT)

    Returns:
        pd.DataFrame s výsledky dotazu
    """
    try:
        print("  → Navazuji spojení s SQL Serverem...")
        with pyodbc.connect(conn_str, timeout=15) as conn:
            print("  → Spojení navázáno. Spouštím SQL dotaz...")
            df = pd.read_sql(query, conn)
            print(f"  → Načteno {len(df)} záznamů z databáze.")
            return df

    except pyodbc.OperationalError as e:
        # Typická chyba: nesprávný server/databáze nebo ODBC driver není nainstalován
        print(f"\n[CHYBA] Nelze navázat spojení: {e}")
        print("  Zkontrolujte: název serveru, název DB, ODBC driver a firewall.")
        raise


def export_to_csv(df: pd.DataFrame, output_path: str) -> None:
    """
    Exportuje DataFrame do CSV souboru.
    Používá středník jako oddělovač (standard v CZ Excelu).

    Args:
        df:          Vstupní DataFrame
        output_path: Cílová cesta k souboru
    """
    df.to_csv(
        output_path,
        index=False,            # Nechceme automatický index pandas
        sep=";",                # Středník = CZ standard (Excel jej automaticky rozpozná)
        encoding="utf-8-sig",   # BOM prefix – Excel správně zobrazí háčky a čárky
        decimal=",",            # CZ formát čísel (desetinná čárka místo tečky)
        date_format="%d.%m.%Y"  # Formát data: 25.03.2025 (CZ standard)
    )
    print(f"  → Soubor uložen: {output_path}")


def add_summary_section(df: pd.DataFrame) -> None:
    """Vypíše do konzole přehledné shrnutí exportovaných dat."""
    print("\n" + "=" * 60)
    print("  SHRNUTÍ KRITICKÝCH PŘÍPADŮ")
    print("=" * 60)
    print(f"  Celkem kritických úvěrů:    {len(df)}")
    print(f"  Celkový zustatek (CZK):     {df['Zustatek CZK'].sum():,.0f} CZK")
    print(f"  Průměrný DPD:               {df['DPD - dny v prodleni'].mean():.0f} dní")
    print(f"  Max. DPD:                   {df['DPD - dny v prodleni'].max()} dní")
    print()
    print("  Rozdělení dle kategorie:")
    for kat, pocet in df["Rizikova kategorie"].value_counts().items():
        print(f"    - {kat:<20} {pocet} případ(ů)")
    print("=" * 60)


# ==============================================================
# SEKCE 5: HLAVNÍ BLOK – SPUŠTĚNÍ
# ==============================================================

if __name__ == "__main__":

    print("\n" + "=" * 60)
    print("  BANKRISK_DB – Export kritických případů")
    print(f"  Datum spuštění: {datetime.now().strftime('%d.%m.%Y %H:%M:%S')}")
    print("=" * 60 + "\n")

    try:
        # Krok 1: Sestavení connection stringu
        conn_str = build_connection_string(DB_CONFIG)

        # Krok 2: Načtení dat z databáze
        df_kriticke = fetch_risk_data(conn_str, SQL_QUERY)

        # Krok 3: Kontrola – je vůbec co exportovat?
        if df_kriticke.empty:
            print("  [INFO] Žádné kritické případy k exportu. CSV nebude vytvořen.")
        else:
            # Krok 4: Export do CSV
            export_to_csv(df_kriticke, OUTPUT_PATH)

            # Krok 5: Shrnutí v konzoli
            add_summary_section(df_kriticke)

            print(f"\n  [ÚSPĚCH] Export dokončen.")
            print(f"  Soubor: {OUTPUT_FILENAME}\n")

    except Exception as e:
        print(f"\n  [KRITICKÁ CHYBA] Skript selhal: {e}")
        raise SystemExit(1)
