//
//  Game.swift
//  PokéJournal Capture
//

import Foundation
import SwiftData

@Model
final class Game {
    @Attribute(.unique) var name: String
    var slug: String
    var lastUsedAt: Date?
    @Relationship(deleteRule: .cascade) var lastKnownTeam: [TeamMember]

    init(name: String, slug: String) {
        self.name = name
        self.slug = slug
        self.lastUsedAt = nil
        self.lastKnownTeam = []
    }

    func markUsed() {
        lastUsedAt = .now
    }

    static let predefinedGames: [(name: String, slug: String)] = [
        ("Pokémon Purpur", "purpur"),
        ("Pokémon Karmesin", "karmesin"),
        ("Pokémon Legenden: Arceus", "arceus"),
        ("Pokémon Strahlender Diamant", "diamant"),
        ("Pokémon Leuchtende Perle", "perle"),
        ("Pokémon Schwert", "schwert"),
        ("Pokémon Schild", "schild")
    ]
}
