//
//  GamePickerView.swift
//  PokéJournal Capture
//

import SwiftUI
import SwiftData

struct GamePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedGame: Game?

    @Query(sort: \Game.lastUsedAt, order: .reverse)
    private var games: [Game]

    @State private var searchText = ""

    private var filteredGames: [Game] {
        if searchText.isEmpty {
            return games
        }
        return games.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var recentGames: [Game] {
        Array(games.filter { $0.lastUsedAt != nil }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            List {
                if !recentGames.isEmpty && searchText.isEmpty {
                    Section("Zuletzt gespielt") {
                        ForEach(recentGames) { game in
                            gameRow(game)
                        }
                    }
                }

                Section(searchText.isEmpty ? "Alle Spiele" : "Suchergebnisse") {
                    ForEach(filteredGames) { game in
                        gameRow(game)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Spiel suchen")
            .navigationTitle("Spiel wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                ensureDefaultGamesExist()
            }
        }
    }

    private func gameRow(_ game: Game) -> some View {
        Button {
            selectGame(game)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(game.name)
                        .fontWeight(.medium)
                    if let lastUsed = game.lastUsedAt {
                        Text("Zuletzt: \(lastUsed, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if selectedGame?.id == game.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func selectGame(_ game: Game) {
        game.markUsed()
        selectedGame = game
        try? modelContext.save()
        dismiss()
    }

    private func ensureDefaultGamesExist() {
        guard games.isEmpty else { return }

        for gameData in Game.predefinedGames {
            let game = Game(name: gameData.name, slug: gameData.slug)
            modelContext.insert(game)
        }
        try? modelContext.save()
    }
}

#Preview {
    GamePickerView(selectedGame: .constant(nil))
        .modelContainer(for: Game.self, inMemory: true)
}
