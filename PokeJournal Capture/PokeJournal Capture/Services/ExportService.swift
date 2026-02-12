//
//  ExportService.swift
//  PokéJournal Capture
//

import Foundation

enum ExportService {
    static func generateMarkdown(for session: DraftSession) -> String {
        var lines: [String] = []

        // Date header
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        lines.append("# \(dateFormatter.string(from: session.date))")
        lines.append("")

        // Activities
        lines.append("## Aktivitäten")
        if session.activities.isEmpty {
            lines.append("*Keine Aktivitäten erfasst*")
        } else {
            lines.append(session.activities)
        }
        lines.append("")

        // Plans
        lines.append("## Pläne")
        if session.plans.isEmpty {
            lines.append("*Keine Pläne erfasst*")
        } else {
            lines.append(session.plans)
        }
        lines.append("")

        // Thoughts
        lines.append("## Gedanken")
        if session.thoughts.isEmpty {
            lines.append("*Keine Gedanken erfasst*")
        } else {
            lines.append(session.thoughts)
        }
        lines.append("")

        // Team
        lines.append("## Team")
        if session.team.isEmpty {
            lines.append("*Kein Team erfasst*")
        } else {
            let sortedTeam = session.team.sorted { $0.slotIndex < $1.slotIndex }
            for member in sortedTeam {
                lines.append("- \(member.formattedForExport)")
            }
        }

        return lines.joined(separator: "\n")
    }
}
