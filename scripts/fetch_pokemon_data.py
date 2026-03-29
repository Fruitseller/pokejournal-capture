#!/usr/bin/env python3
"""Fetch Pokémon data from PokéAPI CSV dumps and generate pokemon.json.

Downloads CSV files from the PokéAPI GitHub repository and produces a JSON
file with the schema: {id, name_de, name_en, types} — German type names.

Usage:
    python3 scripts/fetch_pokemon_data.py
    python3 scripts/fetch_pokemon_data.py --output path/to/pokemon.json
    python3 scripts/fetch_pokemon_data.py --limit 151
"""

import argparse
import csv
import io
import json
import os
import urllib.error
import urllib.request

BASE_URL = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv"

CSV_URLS = {
    "pokemon": f"{BASE_URL}/pokemon.csv",
    "pokemon_species_names": f"{BASE_URL}/pokemon_species_names.csv",
    "pokemon_types": f"{BASE_URL}/pokemon_types.csv",
    "type_names": f"{BASE_URL}/type_names.csv",
}

# Language IDs in PokéAPI: 6 = German, 9 = English
LANG_DE = 6
LANG_EN = 9

DEFAULT_OUTPUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "PokeJournal Capture",
    "PokeJournal Capture",
    "Resources",
    "pokemon.json",
)


def fetch_csv(url: str) -> list[dict]:
    """Download a CSV file and return rows as list of dicts."""
    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            text = response.read().decode("utf-8")
    except urllib.error.URLError as e:
        raise SystemExit(
            f"Failed to fetch {url}: {e}\nCheck your network connection."
        ) from e
    reader = csv.DictReader(io.StringIO(text))
    return list(reader)


def build_pokemon_json(limit: int | None = None) -> list[dict]:
    """Fetch CSVs and build the Pokémon data list."""
    print("Fetching CSV data from PokéAPI...")

    pokemon_rows = fetch_csv(CSV_URLS["pokemon"])
    species_names_rows = fetch_csv(CSV_URLS["pokemon_species_names"])
    pokemon_types_rows = fetch_csv(CSV_URLS["pokemon_types"])
    type_names_rows = fetch_csv(CSV_URLS["type_names"])

    # Build German type name lookup: type_id -> German name
    german_type_names = {}
    for row in type_names_rows:
        if int(row["local_language_id"]) == LANG_DE:
            german_type_names[int(row["type_id"])] = row["name"]

    # Build species name lookups: species_id -> name
    names_de = {}
    names_en = {}
    for row in species_names_rows:
        species_id = int(row["pokemon_species_id"])
        lang_id = int(row["local_language_id"])
        if lang_id == LANG_DE:
            names_de[species_id] = row["name"]
        elif lang_id == LANG_EN:
            names_en[species_id] = row["name"]

    # Build type assignments: pokemon_id -> [type_id, ...] (ordered by slot)
    pokemon_type_map: dict[int, list[tuple[int, int]]] = {}
    for row in pokemon_types_rows:
        pid = int(row["pokemon_id"])
        type_id = int(row["type_id"])
        slot = int(row["slot"])
        if pid not in pokemon_type_map:
            pokemon_type_map[pid] = []
        pokemon_type_map[pid].append((slot, type_id))

    # Build final list from pokemon.csv (base forms only: id < 10000)
    result = []
    for row in pokemon_rows:
        pokemon_id = int(row["id"])
        if pokemon_id >= 10000:
            continue

        species_id = int(row["species_id"])
        name_de = names_de.get(species_id)
        name_en = names_en.get(species_id)

        if not name_de or not name_en:
            continue

        type_slots = pokemon_type_map.get(pokemon_id, [])
        type_slots.sort(key=lambda x: x[0])
        types = [german_type_names[tid] for _, tid in type_slots if tid in german_type_names]

        if not types:
            continue

        result.append({
            "id": pokemon_id,
            "name_de": name_de,
            "name_en": name_en,
            "types": types,
        })

    result.sort(key=lambda p: p["id"])

    if limit is not None:
        result = result[:limit]

    print(f"Generated data for {len(result)} Pokémon.")
    return result


def main():
    parser = argparse.ArgumentParser(
        description="Fetch Pokémon data and generate pokemon.json"
    )
    parser.add_argument(
        "--output",
        default=DEFAULT_OUTPUT,
        help="Output path for pokemon.json",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit number of Pokémon (for debugging)",
    )
    args = parser.parse_args()

    pokemon_data = build_pokemon_json(limit=args.limit)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(pokemon_data, f, ensure_ascii=False, indent=2)

    print(f"Written to {args.output}")


if __name__ == "__main__":
    main()
