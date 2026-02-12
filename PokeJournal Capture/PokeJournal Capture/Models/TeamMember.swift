//
//  TeamMember.swift
//  PokéJournal Capture
//

import Foundation
import SwiftData

@Model
final class TeamMember {
    var pokemonName: String
    var level: Int
    var variant: String?
    var nationalDexNumber: Int?
    var slotIndex: Int

    init(
        pokemonName: String,
        level: Int = 1,
        variant: String? = nil,
        nationalDexNumber: Int? = nil,
        slotIndex: Int = 0
    ) {
        self.pokemonName = pokemonName
        self.level = level
        self.variant = variant
        self.nationalDexNumber = nationalDexNumber
        self.slotIndex = slotIndex
    }

    var displayName: String {
        if let variant = variant, !variant.isEmpty {
            return "\(variant) \(pokemonName)"
        }
        return pokemonName
    }

    var formattedForExport: String {
        "\(displayName) lvl \(level)"
    }
}
