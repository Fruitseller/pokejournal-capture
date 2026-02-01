//
//  DraftSession.swift
//  PokéJournal Capture
//

import Foundation
import SwiftData

@Model
final class DraftSession {
    var game: Game?
    var date: Date
    var activities: String
    var plans: String
    var thoughts: String
    @Relationship(deleteRule: .cascade) var team: [TeamMember]
    var voiceNotes: [String]
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date

    var isDraft: Bool {
        statusRaw == "draft"
    }

    var isExported: Bool {
        statusRaw == "exported"
    }

    init(
        game: Game? = nil,
        date: Date = .now,
        activities: String = "",
        plans: String = "",
        thoughts: String = "",
        team: [TeamMember] = [],
        voiceNotes: [String] = [],
        isDraft: Bool = true
    ) {
        self.game = game
        self.date = date
        self.activities = activities
        self.plans = plans
        self.thoughts = thoughts
        self.team = team
        self.voiceNotes = voiceNotes
        self.statusRaw = isDraft ? "draft" : "exported"
        self.createdAt = .now
        self.updatedAt = .now
    }

    func markUpdated() {
        updatedAt = .now
    }

    func markExported() {
        statusRaw = "exported"
    }
}
