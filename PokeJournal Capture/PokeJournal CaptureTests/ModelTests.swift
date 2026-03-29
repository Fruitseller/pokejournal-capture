import Testing
import Foundation
@testable import PokeJournal_Capture

@Suite
struct TeamMemberTests {

    @Test func displayNameWithoutVariant() {
        let member = TeamMember(pokemonName: "Pikachu", level: 25)
        #expect(member.displayName == "Pikachu")
    }

    @Test func displayNameWithVariant() {
        let member = TeamMember(pokemonName: "Vulpix", level: 38, variant: "Alola")
        #expect(member.displayName == "Alola Vulpix")
    }

    @Test func displayNameWithEmptyVariant() {
        let member = TeamMember(pokemonName: "Glumanda", level: 10, variant: "")
        #expect(member.displayName == "Glumanda")
    }

    @Test func formattedForExportPlain() {
        let member = TeamMember(pokemonName: "Pikachu", level: 45)
        #expect(member.formattedForExport == "Pikachu lvl 45")
    }

    @Test func formattedForExportWithVariant() {
        let member = TeamMember(pokemonName: "Vulpix", level: 38, variant: "Alola")
        #expect(member.formattedForExport == "Alola Vulpix lvl 38")
    }
}

@Suite
struct DraftSessionTests {

    @Test func defaultInitCreatesDraft() {
        let session = DraftSession()
        #expect(session.isDraft == true)
        #expect(session.isExported == false)
        #expect(session.statusRaw == "draft")
    }

    @Test func markExportedChangesStatus() {
        let session = DraftSession()
        session.markExported()
        #expect(session.isExported == true)
        #expect(session.isDraft == false)
        #expect(session.statusRaw == "exported")
    }

    @Test func markUpdatedChangesTimestamp() throws {
        let session = DraftSession()
        let original = session.updatedAt
        Thread.sleep(forTimeInterval: 0.01)
        session.markUpdated()
        #expect(session.updatedAt > original)
    }

    @Test func defaultFieldsAreEmpty() {
        let session = DraftSession()
        #expect(session.activities.isEmpty)
        #expect(session.plans.isEmpty)
        #expect(session.thoughts.isEmpty)
        #expect(session.team.isEmpty)
        #expect(session.voiceNotes.isEmpty)
        #expect(session.game == nil)
    }

    @Test func initWithExplicitValues() {
        let session = DraftSession(
            activities: "Arena",
            plans: "Route 5",
            thoughts: "Gut"
        )
        #expect(session.activities == "Arena")
        #expect(session.plans == "Route 5")
        #expect(session.thoughts == "Gut")
    }
}
