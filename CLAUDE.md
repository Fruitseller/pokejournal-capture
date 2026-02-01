# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PokéJournal Capture is a native iOS companion app for capturing Pokémon gaming session notes. Built with SwiftUI + SwiftData, targeting iOS 26+.

**Language:** All UI strings and Pokémon data are in German.

## Build Commands

```bash
# List available schemes
xcodebuild -list -project "PokéJournal Capture/PokéJournal Capture.xcodeproj"

# Build for simulator
xcodebuild build \
  -project "PokéJournal Capture/PokéJournal Capture.xcodeproj" \
  -scheme "PokéJournal Capture" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run tests
xcodebuild test \
  -project "PokéJournal Capture/PokéJournal Capture.xcodeproj" \
  -scheme "PokéJournal Capture" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Architecture

**Stack:** SwiftUI + SwiftData (not Core Data), MVVM pattern

**SwiftData Models** (`Models/`):
- `DraftSession` - Main session entity with game, date, activities, plans, thoughts, team, voiceNotes, status
- `Game` - Managed games with @unique name constraint
- `TeamMember` - Pokemon slot with name, level, variant, nationalDexNumber

**Non-SwiftData:**
- `Pokemon` - Codable struct loaded from `pokemon.json`
- `PokemonDataStore` - Singleton @MainActor ObservableObject for Pokemon lookup

**Key Views** (`Views/`):
- `SessionEditorView` - Main editor with 10s autosave timer
- `TeamEditorView` - 3x2 grid with PokemonSearchView component
- `VoiceRecorderView` - Contains embedded `SpeechRecognizer` class using Speech framework (de-DE locale)

**Services** (`Services/`):
- `ExportService` - Generates Markdown export format

## Important Implementation Details

- App entry point: `Poke_Journal_CaptureApp.swift` configures SwiftData `ModelContainer`
- `ContentView.swift` handles root navigation between editor and drafts list
- Voice recording requires `SFSpeechRecognizer` authorization + microphone permission
- `pokemon.json` in `Resources/` contains 261 Pokémon with German/English names and types
- SwiftUI previews may not work reliably; use Simulator (Cmd+R) for testing

## Export Format

Sessions export to clipboard as Markdown:
```markdown
# YYYY-MM-DD

## Aktivitäten
[content]

## Pläne
[content]

## Gedanken
[content]

## Team
- [Variante] [Name] lvl [Level]
```
