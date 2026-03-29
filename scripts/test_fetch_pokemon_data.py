#!/usr/bin/env python3
"""Integration tests for fetch_pokemon_data.py.

Runs the fetch script and validates the generated pokemon.json matches
the expected schema and content requirements.
"""

import json
import os
import subprocess
import sys
import tempfile
import unittest

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FETCH_SCRIPT = os.path.join(SCRIPT_DIR, "fetch_pokemon_data.py")


class TestFetchPokemonData(unittest.TestCase):
    """Validate that fetch_pokemon_data.py produces correct output."""

    @classmethod
    def setUpClass(cls):
        """Run the fetch script once into a temp directory."""
        cls.tmpdir = tempfile.mkdtemp()
        cls.output_path = os.path.join(cls.tmpdir, "pokemon.json")
        result = subprocess.run(
            [sys.executable, FETCH_SCRIPT, "--output", cls.output_path],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"fetch_pokemon_data.py failed:\n{result.stderr}"
            )
        with open(cls.output_path, encoding="utf-8") as f:
            cls.pokemon_list = json.load(f)

    # -- Schema tests --

    def test_output_is_list(self):
        self.assertIsInstance(self.pokemon_list, list)

    def test_not_empty(self):
        self.assertGreater(len(self.pokemon_list), 0)

    def test_has_more_than_261_pokemon(self):
        """The whole point: more Pokémon than the old static file."""
        self.assertGreater(len(self.pokemon_list), 261)

    def test_each_entry_has_required_keys(self):
        required = {"id", "name_de", "name_en", "types"}
        for entry in self.pokemon_list:
            self.assertEqual(
                set(entry.keys()),
                required,
                f"Entry {entry.get('id', '?')} has wrong keys: {set(entry.keys())}",
            )

    def test_id_is_int(self):
        for entry in self.pokemon_list:
            self.assertIsInstance(entry["id"], int, f"id not int: {entry}")

    def test_names_are_nonempty_strings(self):
        for entry in self.pokemon_list:
            self.assertIsInstance(entry["name_de"], str)
            self.assertIsInstance(entry["name_en"], str)
            self.assertTrue(len(entry["name_de"]) > 0, f"Empty name_de: {entry}")
            self.assertTrue(len(entry["name_en"]) > 0, f"Empty name_en: {entry}")

    def test_types_is_nonempty_list_of_strings(self):
        for entry in self.pokemon_list:
            self.assertIsInstance(entry["types"], list)
            self.assertGreater(len(entry["types"]), 0, f"Empty types: {entry}")
            for t in entry["types"]:
                self.assertIsInstance(t, str)

    # -- Content tests --

    def test_ids_are_sorted(self):
        ids = [p["id"] for p in self.pokemon_list]
        self.assertEqual(ids, sorted(ids))

    def test_no_duplicate_ids(self):
        ids = [p["id"] for p in self.pokemon_list]
        self.assertEqual(len(ids), len(set(ids)))

    def test_no_ids_above_10000(self):
        """Mega, Gmax, etc. should be filtered out."""
        for entry in self.pokemon_list:
            self.assertLess(
                entry["id"], 10000, f"Non-base form included: {entry}"
            )

    def test_types_are_german(self):
        """Types must be German names, not English identifiers."""
        german_types = {
            "Normal", "Feuer", "Wasser", "Pflanze", "Elektro", "Eis",
            "Kampf", "Gift", "Boden", "Flug", "Psycho", "Käfer",
            "Gestein", "Geist", "Drache", "Unlicht", "Stahl", "Fee",
        }
        all_types = set()
        for entry in self.pokemon_list:
            all_types.update(entry["types"])
        self.assertTrue(
            all_types.issubset(german_types),
            f"Non-German types found: {all_types - german_types}",
        )

    def test_well_known_pokemon_present(self):
        """Spot-check some well-known Pokémon."""
        by_id = {p["id"]: p for p in self.pokemon_list}

        # Bulbasaur
        self.assertIn(1, by_id)
        self.assertEqual(by_id[1]["name_de"], "Bisasam")
        self.assertEqual(by_id[1]["name_en"], "Bulbasaur")
        self.assertEqual(by_id[1]["types"], ["Pflanze", "Gift"])

        # Pikachu
        self.assertIn(25, by_id)
        self.assertEqual(by_id[25]["name_de"], "Pikachu")
        self.assertEqual(by_id[25]["types"], ["Elektro"])

        # Charizard
        self.assertIn(6, by_id)
        self.assertEqual(by_id[6]["name_en"], "Charizard")
        self.assertEqual(by_id[6]["types"], ["Feuer", "Flug"])

    def test_limit_flag(self):
        """--limit should restrict the number of Pokémon."""
        tmpfile = os.path.join(self.tmpdir, "pokemon_limited.json")
        result = subprocess.run(
            [sys.executable, FETCH_SCRIPT, "--output", tmpfile, "--limit", "10"],
            capture_output=True,
            text=True,
            timeout=120,
        )
        self.assertEqual(result.returncode, 0, f"Script failed: {result.stderr}")
        with open(tmpfile, encoding="utf-8") as f:
            limited = json.load(f)
        self.assertEqual(len(limited), 10)


if __name__ == "__main__":
    unittest.main()
