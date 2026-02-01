# PokéJournal Capture

iOS-Companion-App zur schnellen Erfassung von Pokémon-Session-Notizen während des Spielens.

## Technische Anforderungen

- **iOS:** 17.0+
- **Xcode:** 15+
- **Swift:** 5.9+

## Features

- **Quick-Start:** App öffnet direkt im "Neue Session"-Modus
- **Voice-to-Text:** Sprachnotizen mit On-Device-Transkription (Speech Framework)
- **Team-Editor:** 6er-Grid für Pokémon-Team mit deutscher Suche
- **Text-Eingabe:** Expandierbare Felder für Aktivitäten, Pläne, Gedanken
- **Export:** Markdown in Zwischenablage kopieren
- **Drafts-Verwaltung:** Nicht-exportierte Sessions fortsetzen oder löschen
- **Spiele-Verwaltung:** Eigene Spiele hinzufügen

## Projektstruktur

```
PokéJournal Capture/
├── Models/
│   ├── DraftSession.swift    # Haupt-Datenmodell für Sessions
│   ├── Game.swift            # Spielverwaltung
│   ├── Pokemon.swift         # Pokémon-Daten und DataStore
│   └── TeamMember.swift      # Team-Mitglieder
├── Views/
│   ├── SessionEditorView.swift   # Hauptansicht zum Bearbeiten
│   ├── GamePickerView.swift      # Spielauswahl
│   ├── TeamEditorView.swift      # Team-Editor mit Pokémon-Suche
│   ├── VoiceRecorderView.swift   # Sprachaufnahme
│   ├── DraftsListView.swift      # Entwürfe-Liste
│   ├── GamesManagementView.swift # Spieleverwaltung
│   └── ExportPreviewView.swift   # Export-Vorschau
├── Services/
│   └── ExportService.swift   # Markdown-Export
├── Resources/
│   └── pokemon.json          # Pokémon-Referenzdaten (DE/EN)
├── ContentView.swift
└── Poke_Journal_CaptureApp.swift
```

## Setup

1. Projekt in Xcode öffnen
2. Im Target unter **Info** diese Privacy-Keys hinzufügen:
   - `Privacy - Microphone Usage Description`
   - `Privacy - Speech Recognition Usage Description`
3. Sicherstellen, dass `pokemon.json` in **Build Phases → Copy Bundle Resources** enthalten ist
4. Build & Run

## Build via CLI

```bash
# Schemes auflisten
xcodebuild -list -project "PokéJournal Capture/PokéJournal Capture.xcodeproj"

# Build
xcodebuild build \
  -project "PokéJournal Capture/PokéJournal Capture.xcodeproj" \
  -scheme "PokéJournal Capture" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Export-Format

Sessions werden als Markdown exportiert:

```markdown
# YYYY-MM-DD

## Aktivitäten
[Inhalt]

## Pläne
[Inhalt]

## Gedanken
[Inhalt]

## Team
- [Variante] [Name] lvl [Level]
- ...
```

## Datenmodell

- **DraftSession:** Lokaler Entwurf einer Session mit Datum, Aktivitäten, Plänen, Gedanken, Team, Sprachnotizen
- **Game:** Spielname und Slug für Dateinamen
- **TeamMember:** Pokémon-Name, Level, optionale Variante (Alola, Galar, etc.)
