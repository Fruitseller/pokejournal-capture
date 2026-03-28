# Plan: Pokémon-Daten per Script laden statt statische JSON

## Motivation

Aktuell liegt eine handgepflegte `pokemon.json` mit 261 Pokémon fest im Repo
(`Resources/pokemon.json`). Das Referenzprojekt
[pokejournal-mac](https://github.com/Fruitseller/pokejournal-mac) löst das
besser: Ein Python-Script (`scripts/fetch_pokemon_data.py`) zieht die Daten
frisch aus den PokéAPI-CSV-Dumps auf GitHub und generiert die JSON-Datei.

**Vorteile:**
- Alle ~1025 Pokémon statt nur 261 — automatisch vollständig
- Daten bleiben aktuell (neue Generationen durch Script-Neustart)
- Kein großes JSON-Blob im Git-Verlauf
- Einheitliche Quelle zwischen Mac- und iOS-App
- Erweiterbar um zusätzliche Felder (Sprites, Evolution-Chains, etc.)

## Ist-Zustand

| Aspekt | Aktuell |
|---|---|
| Datei | `Resources/pokemon.json` — 261 Einträge, eingecheckt |
| Schema | `{ id, name_de, name_en, types }` |
| Typen | Deutsch (`"Pflanze"`, `"Feuer"`, …) |
| Swift-Model | `Pokemon.swift` — `Codable` struct + `PokemonDataStore` Singleton |
| Gitignore | `pokemon.json` ist **nicht** ignoriert |

## Soll-Zustand

| Aspekt | Neu |
|---|---|
| Datei | `Resources/pokemon.json` — generiert, **gitignored** |
| Script | `scripts/fetch_pokemon_data.py` — generiert die JSON |
| Schema | `{ id, name_de, name_en, types }` (identisch, damit Swift-Code unverändert bleibt) |
| Typen | Weiterhin deutsch — Script muss Typ-Namen übersetzen |
| Swift-Model | Keine Änderung nötig |

## Umsetzungsschritte

### 1. Script erstellen: `scripts/fetch_pokemon_data.py`

Orientierung am Mac-Script, aber angepasst:

- **Nur JSON generieren, keine Sprites** — die iOS-App nutzt aktuell keine
  Sprite-Assets, also den Sprite-Download weglassen
- **Pfade anpassen:** Output nach
  `PokeJournal Capture/PokeJournal Capture/Resources/pokemon.json`
- **Typ-Namen auf Deutsch übersetzen:** Die PokéAPI-CSVs liefern
  englische Typ-Identifier (`grass`, `fire`, …). Das Script muss eine
  Mapping-Tabelle Englisch→Deutsch enthalten, damit das bestehende Schema
  (`"Pflanze"`, `"Feuer"`, …) beibehalten wird. Alternativ: deutsche
  Typ-Namen aus `type_names.csv` (language_id 6) ziehen.
- **Nur Base-Forms:** Pokémon mit `id > 10000` (Mega, Gmax, etc.)
  herausfiltern, wie im Mac-Script
- **Schema-Kompatibilität sicherstellen:** Output-Format muss exakt
  `{ id, name_de, name_en, types }` sein — keine neuen Felder, damit
  `Pokemon.swift` ohne Änderung funktioniert

```
CSV-Quellen (4 HTTP-Requests statt tausender API-Calls):
  - pokemon.csv              → ID, species_id
  - pokemon_species_names.csv → deutsche + englische Namen
  - pokemon_types.csv         → Typ-Zuordnung
  - type_names.csv            → deutsche Typ-Namen (language_id 6)
```

### 2. `.gitignore` erweitern

```gitignore
# Generated Pokemon data — regenerate with: python3 scripts/fetch_pokemon_data.py
PokeJournal Capture/PokeJournal Capture/Resources/pokemon.json
```

### 3. Setup-Dokumentation in CLAUDE.md aktualisieren

Build-Commands-Abschnitt ergänzen:

```bash
# Pokemon-Daten generieren (einmalig nach Clone)
python3 scripts/fetch_pokemon_data.py
```

Hinweis unter "Important Implementation Details":
- `pokemon.json` ist generiert und gitignored
- Bei fehlendem JSON startet die App mit leerer Pokémon-Liste
  (bestehendes Fehlerverhalten in `PokemonDataStore.loadPokemon()`)

### 4. Robustheit: Fehlende JSON abfangen

`PokemonDataStore` gibt bereits eine Warnung aus, wenn die JSON fehlt
(`"Pokemon JSON not found in bundle"`). Das reicht als Mindest-Handling.

**Optional:** Eine deutlichere Fehlermeldung in der UI anzeigen, falls
`pokemon` leer ist — z.B. ein Hinweis in der `PokemonSearchView`, dass
`scripts/fetch_pokemon_data.py` ausgeführt werden muss. Niedrige Priorität.

### 5. Bestehende JSON entfernen

Sobald Script und Gitignore stehen:

```bash
git rm "PokeJournal Capture/PokeJournal Capture/Resources/pokemon.json"
python3 scripts/fetch_pokemon_data.py
# → JSON wird neu generiert, aber nicht mehr getrackt
```

### 6. Tests anpassen

Die bestehenden Tests, die Pokémon-Daten laden, müssen weiterhin
funktionieren. Zwei Optionen:

- **Option A (bevorzugt):** Tests nutzen eine kleine Test-Fixture-JSON im
  Test-Bundle — unabhängig von der generierten Datei
- **Option B:** `script/test` stellt sicher, dass `fetch_pokemon_data.py`
  vor dem Testlauf ausgeführt wird (CI-Abhängigkeit)

Option A ist robuster, weil Tests nicht von Netzwerk oder generierten
Dateien abhängen.

## Offene Entscheidungen

1. **Deutsche Typ-Namen:** Aus `type_names.csv` ziehen (sauberer, aber ein
   zusätzlicher CSV-Download) oder Mapping-Dict im Script hartcodieren
   (einfacher, aber manuell zu pflegen)?
   → Empfehlung: `type_names.csv` nutzen, da PokéAPI die deutschen Namen
   bereits hat.

2. **Wie viele Pokémon einschließen?** Alle ~1025 Base-Forms oder per
   `--limit` einschränkbar wie im Mac-Script?
   → Empfehlung: Alle laden, `--limit` als optionalen Parameter für
   Entwicklung/Debugging anbieten.

3. **Sollen zukünftig weitere Felder ins Schema?** (z.B. `evolution_chain_id`,
   `sprite_url`) Falls ja, wäre jetzt ein guter Zeitpunkt, das Schema zu
   erweitern.
   → Empfehlung: Erstmal Schema beibehalten, Erweiterung separat planen.

## Risiken

- **Netzwerk-Abhängigkeit beim Setup:** Neuer Klon braucht Internet, um
  `pokemon.json` zu generieren. Akzeptabel — ist ohnehin nur ein
  Entwickler-Setup-Schritt.
- **PokéAPI-CSV-Format ändert sich:** Unwahrscheinlich, aber möglich. Bei
  Script-Fehler ist die Ursache leicht zu diagnostizieren.
- **Xcode-Build ohne JSON:** Wenn jemand das Script vergisst, fehlt die
  Resource im Bundle. Build schlägt nicht fehl, aber die Pokémon-Liste
  bleibt leer. Die bestehende Fehlerbehandlung fängt das ab.
