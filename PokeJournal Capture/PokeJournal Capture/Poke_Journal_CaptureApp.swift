//
//  Poke_Journal_CaptureApp.swift
//  PokéJournal Capture
//
//  Created by Piotr Großmann on 31.01.26.
//

import SwiftUI
import SwiftData

@main
struct Poke_Journal_CaptureApp: App {
    // Trigger async Pokemon loading early so data is ready when needed.
    private let _pokemonStore = PokemonDataStore.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DraftSession.self,
            Game.self,
            TeamMember.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
