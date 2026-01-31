# Projekt 2: PokéJournal Capture (iOS App)

## Übersicht
Companion-App zur schnellen Erfassung von Session-Notizen während des Spielens. Fokus auf minimale Friction.

## Technische Eckdaten
- **Plattform:** iOS 26+
- **IDE:** Xcode 26
- **Framework:** SwiftUI + SwiftData
- **Sprache:** Swift 6.2+
- **AI:** Foundation Models Framework (on-device LLM für Transkription und Strukturierung)
- **Design:** Liquid Glass Design Language

## Datenmodell

### Entitäten
- **DraftSession:** Lokaler Entwurf einer Session
  - Game (String, z.B. "purpur")
  - Datum
  - Aktivitäten (String)
  - Pläne (String)
  - Gedanken (String)
  - Team (Array von TeamMember)
  - VoiceNotes (Array von Transkriptionen)
  - Status: draft / exported

- **RecentGame:** Zuletzt verwendete Spiele für Quick-Access

- **TeamMember:**
  - Pokémon-Name (String)
  - Level (Int)
  - Variante (Optional String, z.B. "Aloha")

### Pokémon-Referenzdaten
- Eigene lokale JSON-Datei
- Name DE/EN, Nationaldex-Nummer, Typen, Sprite-URLs

## Features

### 1. Quick-Start
- App öffnet direkt in "Neue Session" Modus
- Spiel aus Liste der letzten 5 wählen (oder suchen)
- Datum ist automatisch heute

### 2. Voice-to-Text Erfassung
- Großer Mikrofon-Button mit Liquid Glass Styling
- On-device Transkription via Foundation Models Framework
- Transkription erscheint in Echtzeit
- Benutzer wählt danach Ziel-Section (Aktivitäten/Pläne/Gedanken)
- Mehrere Voice Notes pro Session möglich, werden konkateniert
- Optional: Foundation Models zur automatischen Strukturierung/Bereinigung der Transkription

### 3. Team-Editor
- 6er-Grid, initial leer
- Tap auf Slot → Pokémon-Suche (mit deutschen Namen)
- Pokémon-Liste lokal
- Nach Auswahl: Level-Eingabe via NumberPad
- Swipe zum Entfernen
- "Team von letzter Session kopieren" Button

### 4. Text-Eingabe
- Für die, die doch tippen wollen
- Drei expandierbare Textfelder (Aktivitäten, Pläne, Gedanken)
- Autosave alle 10 Sekunden

### 5. Export
- "In Zwischenablage kopieren" Button
- Generiert Markdown-Inhalt im korrekten Format (ohne Datei-Header, nur der Content):
```
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
- Visuelles Feedback nach Kopieren (Haptic + kurze Bestätigung)
- Optional: Preview vor dem Kopieren

### 6. Drafts-Verwaltung
- Liste aller nicht-exportierten Sessions
- Fortsetzen oder Löschen
- Warnung wenn App geschlossen wird mit nicht-exportiertem Draft

### 7. Spiele-Verwaltung
- Liste der bekannten Spiele (manuell hinzufügen)
- Pro Spiel: Name, Dateiname-Slug
- Optional: Letztes bekanntes Team (für "Team kopieren" Feature)

## UI/UX Richtlinien
- Liquid Glass Design: Transparente Navigation, schwebende Buttons
- One-handed use optimiert
- Große Touch-Targets
- Haptic Feedback bei Voice Recording Start/Stop und erfolgreichem Kopieren
- Dark Mode Standard

## Nicht im Scope v1
- Anzeige vergangener Sessions
- Apple Watch Companion
- Widgets
- Share Sheet / Obsidian-Integration


