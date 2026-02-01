//
//  GamesManagementView.swift
//  PokéJournal Capture
//

import SwiftUI
import SwiftData

struct GamesManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Game.name)
    private var games: [Game]

    @State private var showingAddGame = false
    @State private var newGameName = ""
    @State private var newGameSlug = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(games) { game in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name)
                            .fontWeight(.medium)
                        Text("Slug: \(game.slug)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let lastUsed = game.lastUsedAt {
                            Text("Zuletzt: \(lastUsed, style: .relative)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: deleteGames)
            }
            .navigationTitle("Spiele verwalten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddGame = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Neues Spiel", isPresented: $showingAddGame) {
                TextField("Name", text: $newGameName)
                TextField("Slug (z.B. purpur)", text: $newGameSlug)
                Button("Abbrechen", role: .cancel) {
                    resetNewGameFields()
                }
                Button("Hinzufügen") {
                    addGame()
                }
                .disabled(newGameName.isEmpty || newGameSlug.isEmpty)
            }
            .onAppear {
                ensureDefaultGamesExist()
            }
        }
    }

    private func addGame() {
        let game = Game(name: newGameName, slug: newGameSlug.lowercased())
        modelContext.insert(game)
        try? modelContext.save()
        resetNewGameFields()
    }

    private func resetNewGameFields() {
        newGameName = ""
        newGameSlug = ""
    }

    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(games[index])
        }
        try? modelContext.save()
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
    GamesManagementView()
        .modelContainer(for: Game.self, inMemory: true)
}
