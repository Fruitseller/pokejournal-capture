//
//  Pokemon.swift
//  PokéJournal Capture
//

import Foundation
import Combine

struct Pokemon: Codable, Identifiable, Hashable {
    let id: Int
    let nameDE: String
    let nameEN: String
    let types: [String]

    var displayName: String { nameDE }

    enum CodingKeys: String, CodingKey {
        case id
        case nameDE = "name_de"
        case nameEN = "name_en"
        case types
    }
}

@MainActor
final class PokemonDataStore: ObservableObject {
    static let shared = PokemonDataStore()

    @Published private(set) var pokemon: [Pokemon] = []
    @Published private(set) var isLoaded = false

    private init() {
        Task.detached(priority: .userInitiated) {
            let loaded = Self.decodePokemonFromBundle()
            await MainActor.run {
                self.pokemon = loaded
                self.isLoaded = true
            }
        }
    }

    #if DEBUG
    /// Test-only initializer that skips bundle loading.
    init(testPokemon: [Pokemon]) {
        self.pokemon = testPokemon
        self.isLoaded = true
    }
    #endif

    /// Pure decoding on the calling thread — no main-actor dependency.
    private nonisolated static func decodePokemonFromBundle() -> [Pokemon] {
        guard let url = Bundle.main.url(forResource: "pokemon", withExtension: "json") else {
            print("Pokemon JSON not found in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Pokemon].self, from: data)
        } catch {
            print("Failed to load Pokemon data: \(error)")
            return []
        }
    }

    func search(query: String) -> [Pokemon] {
        guard !query.isEmpty else { return pokemon }
        let lowercased = query.lowercased()
        return pokemon.filter { pokemon in
            pokemon.nameDE.lowercased().contains(lowercased) ||
            pokemon.nameEN.lowercased().contains(lowercased) ||
            String(pokemon.id) == query
        }
    }

    func pokemon(byId id: Int) -> Pokemon? {
        pokemon.first { $0.id == id }
    }

    func pokemon(byName name: String) -> Pokemon? {
        pokemon.first { $0.nameDE == name || $0.nameEN == name }
    }
}
