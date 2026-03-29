import Testing
import Foundation
@testable import PokeJournal_Capture

struct PokemonDecodingTests {

    private func loadFixture() throws -> [Pokemon] {
        guard let url = Bundle(for: BundleToken.self)
            .url(forResource: "pokemon_test", withExtension: "json") else {
            throw FixtureError.missingFile("pokemon_test.json not found in test bundle")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Pokemon].self, from: data)
    }

    @Test func decodesAllEntriesFromFixture() throws {
        let pokemon = try loadFixture()
        #expect(pokemon.count == 5)
    }

    @Test func decodesIdAndNames() throws {
        let pokemon = try loadFixture()
        let bulbasaur = pokemon[0]
        #expect(bulbasaur.id == 1)
        #expect(bulbasaur.nameDE == "Bisasam")
        #expect(bulbasaur.nameEN == "Bulbasaur")
    }

    @Test func decodesTypes() throws {
        let pokemon = try loadFixture()
        let bulbasaur = pokemon[0]
        #expect(bulbasaur.types == ["Pflanze", "Gift"])

        let charmander = pokemon[1]
        #expect(charmander.types == ["Feuer"])
    }

    @Test func displayNameIsGerman() throws {
        let pokemon = try loadFixture()
        #expect(pokemon[0].displayName == "Bisasam")
    }

    @Test func roundTripsToJSON() throws {
        let original = Pokemon(id: 25, nameDE: "Pikachu", nameEN: "Pikachu", types: ["Elektro"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Pokemon.self, from: data)
        #expect(decoded == original)
    }
}

@MainActor
struct PokemonSearchTests {

    private let store = PokemonDataStore(testPokemon: [
        Pokemon(id: 1, nameDE: "Bisasam", nameEN: "Bulbasaur", types: ["Pflanze", "Gift"]),
        Pokemon(id: 4, nameDE: "Glumanda", nameEN: "Charmander", types: ["Feuer"]),
        Pokemon(id: 25, nameDE: "Pikachu", nameEN: "Pikachu", types: ["Elektro"]),
    ])

    @Test func searchByGermanName() {
        let results = store.search(query: "bisa")
        #expect(results.count == 1)
        #expect(results[0].id == 1)
    }

    @Test func searchByEnglishName() {
        let results = store.search(query: "charm")
        #expect(results.count == 1)
        #expect(results[0].id == 4)
    }

    @Test func searchById() {
        let results = store.search(query: "25")
        #expect(results.count == 1)
        #expect(results[0].nameDE == "Pikachu")
    }

    @Test func searchIsCaseInsensitive() {
        let results = store.search(query: "PIKACHU")
        #expect(results.count == 1)
    }

    @Test func emptyQueryReturnsAll() {
        let results = store.search(query: "")
        #expect(results.count == 3)
    }

    @Test func noMatchReturnsEmpty() {
        let results = store.search(query: "zzzzz")
        #expect(results.isEmpty)
    }

    @Test func lookupById() {
        let pokemon = store.pokemon(byId: 25)
        #expect(pokemon?.nameDE == "Pikachu")
        #expect(store.pokemon(byId: 999) == nil)
    }

    @Test func lookupByName() {
        #expect(store.pokemon(byName: "Bisasam")?.id == 1)
        #expect(store.pokemon(byName: "Bulbasaur")?.id == 1)
        #expect(store.pokemon(byName: "Nonexistent") == nil)
    }
}

private enum FixtureError: Error, CustomStringConvertible {
    case missingFile(String)
    var description: String {
        switch self { case .missingFile(let msg): return msg }
    }
}

/// Anchor type to locate the test bundle.
private class BundleToken {}
