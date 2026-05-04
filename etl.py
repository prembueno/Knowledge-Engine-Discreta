"""
ETL - Knowledge Engine: Copas do Mundo (1930-2014)

Le data/WorldCups.csv, normaliza os campos para o formato exigido pelo Prolog
(minusculas, sem acentos, sem espacos) e gera o arquivo copas.pl contendo:
  - os fatos copa/10
  - as regras auxiliares e as regras das 3 perguntas (lidas de regras.pl)

Uso:
    python etl.py
"""

import csv
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).parent
INPUT_CSV = ROOT / "data" / "WorldCups.csv"
RULES_FILE = ROOT / "regras.pl"
OUTPUT_PL = ROOT / "copas.pl"


def to_atom(text: str) -> str:
    """Converte texto em um atomo Prolog valido: minusculo, sem acentos,
    sem espacos, sem caracteres especiais. Ex: 'Germany FR' -> 'germany_fr'."""
    if text is None:
        return "desconhecido"
    s = text.strip()
    s = unicodedata.normalize("NFKD", s).encode("ASCII", "ignore").decode("ASCII")
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "_", s).strip("_")
    return s or "desconhecido"


def parse_attendance(text: str) -> int:
    """O CSV usa formato europeu (ex: '1.045.246'). Remove pontos/virgulas
    e converte para inteiro."""
    return int(text.strip().replace(".", "").replace(",", ""))


def gerar_fatos() -> list[str]:
    fatos = []
    with INPUT_CSV.open(encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if not row.get("Year") or not row["Year"].strip():
                continue
            ano = int(row["Year"])
            sede = to_atom(row["Country"])
            campeao = to_atom(row["Winner"])
            vice = to_atom(row["Runners-Up"])
            terceiro = to_atom(row["Third"])
            quarto = to_atom(row["Fourth"])
            gols = int(row["GoalsScored"])
            times = int(row["QualifiedTeams"])
            partidas = int(row["MatchesPlayed"])
            publico = parse_attendance(row["Attendance"])
            fato = (
                f"copa({ano}, {sede}, {campeao}, {vice}, {terceiro}, "
                f"{quarto}, {gols}, {times}, {partidas}, {publico})."
            )
            fatos.append(fato)
    return fatos


def main() -> None:
    fatos = gerar_fatos()
    regras = RULES_FILE.read_text(encoding="utf-8") if RULES_FILE.exists() else ""

    header = (
        "% =====================================================================\n"
        "% Knowledge Engine - Copas do Mundo (1930-2014)\n"
        "% Arquivo gerado automaticamente por etl.py - NAO EDITAR A MAO\n"
        "% Para regenerar: python etl.py\n"
        "% =====================================================================\n"
        "%\n"
        "% Predicado principal:\n"
        "%   copa(Ano, Sede, Campeao, Vice, Terceiro, Quarto,\n"
        "%        Gols, TimesQualificados, Partidas, Publico).\n"
        "%\n"
        "% Cada fato representa uma edicao da Copa do Mundo FIFA.\n"
        "% Tipos: Ano, Gols, TimesQualificados, Partidas, Publico = inteiros\n"
        "%        Sede, Campeao, Vice, Terceiro, Quarto = atomos (paises)\n"
        "% =====================================================================\n\n"
    )

    with OUTPUT_PL.open("w", encoding="utf-8") as out:
        out.write(header)
        out.write("% --- FATOS (gerados a partir de data/WorldCups.csv) ---\n\n")
        for fato in fatos:
            out.write(fato + "\n")
        out.write("\n")
        if regras:
            out.write(regras)

    print(f"OK - gerado {OUTPUT_PL.name} com {len(fatos)} fatos copa/10.")
    if regras:
        print(f"   regras anexadas a partir de {RULES_FILE.name}")


if __name__ == "__main__":
    main()
