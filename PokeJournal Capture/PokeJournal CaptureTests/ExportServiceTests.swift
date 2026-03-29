import Testing
import Foundation
import SwiftData
@testable import PokeJournal_Capture

private func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: DraftSession.self, Game.self, TeamMember.self,
        configurations: config
    )
}

private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

@Suite
struct ExportServiceTests {

    @Test func fullSessionExportsCorrectMarkdown() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let session = DraftSession(
            date: makeDate(2026, 3, 29),
            activities: "Arena besiegt",
            plans: "Route 5 erkunden",
            thoughts: "Brauche mehr Wasser-Pokemon"
        )
        context.insert(session)

        let member1 = TeamMember(pokemonName: "Pikachu", level: 45, slotIndex: 0)
        let member2 = TeamMember(pokemonName: "Bisasam", level: 32, slotIndex: 1)
        session.team.append(member1)
        session.team.append(member2)

        let markdown = ExportService.generateMarkdown(for: session)

        #expect(markdown.contains("# 2026-03-29"))
        #expect(markdown.contains("## Aktivitäten\nArena besiegt"))
        #expect(markdown.contains("## Pläne\nRoute 5 erkunden"))
        #expect(markdown.contains("## Gedanken\nBrauche mehr Wasser-Pokemon"))
        #expect(markdown.contains("- Pikachu lvl 45"))
        #expect(markdown.contains("- Bisasam lvl 32"))
    }

    @Test func emptySessionExportsPlaceholders() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let session = DraftSession()
        context.insert(session)

        let markdown = ExportService.generateMarkdown(for: session)

        #expect(markdown.contains("*Keine Aktivitäten erfasst*"))
        #expect(markdown.contains("*Keine Pläne erfasst*"))
        #expect(markdown.contains("*Keine Gedanken erfasst*"))
        #expect(markdown.contains("*Kein Team erfasst*"))
    }

    @Test func teamVariantIncludedInExport() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let session = DraftSession()
        context.insert(session)

        let member = TeamMember(pokemonName: "Vulpix", level: 38, variant: "Alola", slotIndex: 0)
        session.team.append(member)

        let markdown = ExportService.generateMarkdown(for: session)

        #expect(markdown.contains("- Alola Vulpix lvl 38"))
    }

    @Test func teamSortedBySlotIndex() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let session = DraftSession()
        context.insert(session)

        session.team.append(TeamMember(pokemonName: "Bisasam", level: 10, slotIndex: 2))
        session.team.append(TeamMember(pokemonName: "Pikachu", level: 50, slotIndex: 0))
        session.team.append(TeamMember(pokemonName: "Glumanda", level: 30, slotIndex: 1))

        let markdown = ExportService.generateMarkdown(for: session)

        let teamSection = markdown.components(separatedBy: "## Team\n").last!
        let lines = teamSection.components(separatedBy: "\n").filter { $0.hasPrefix("- ") }
        #expect(lines.count == 3)
        #expect(lines[0] == "- Pikachu lvl 50")
        #expect(lines[1] == "- Glumanda lvl 30")
        #expect(lines[2] == "- Bisasam lvl 10")
    }

    @Test func sectionsAppearInCorrectOrder() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let session = DraftSession(activities: "a", plans: "b", thoughts: "c")
        context.insert(session)

        let markdown = ExportService.generateMarkdown(for: session)

        let datePos = markdown.range(of: "# ")!.lowerBound
        let activitiesPos = markdown.range(of: "## Aktivitäten")!.lowerBound
        let plansPos = markdown.range(of: "## Pläne")!.lowerBound
        let thoughtsPos = markdown.range(of: "## Gedanken")!.lowerBound
        let teamPos = markdown.range(of: "## Team")!.lowerBound

        #expect(datePos < activitiesPos)
        #expect(activitiesPos < plansPos)
        #expect(plansPos < thoughtsPos)
        #expect(thoughtsPos < teamPos)
    }

    @Test func partialSessionMixesContentAndPlaceholders() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let session = DraftSession(activities: "Gym besiegt", plans: "", thoughts: "Cooles Team")
        context.insert(session)

        let markdown = ExportService.generateMarkdown(for: session)

        #expect(markdown.contains("## Aktivitäten\nGym besiegt"))
        #expect(markdown.contains("*Keine Pläne erfasst*"))
        #expect(markdown.contains("## Gedanken\nCooles Team"))
        #expect(markdown.contains("*Kein Team erfasst*"))
    }
}
