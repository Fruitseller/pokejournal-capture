//
//  ExportService.swift
//  PokéJournal Capture
//

import Foundation

enum ExportService {
    static func generateMarkdown(for session: DraftSession) -> String {
        var lines: [String] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        lines.append("# \(dateFormatter.string(from: session.date))")
        lines.append("")

        lines.append(contentsOf: textSection("Aktivitäten", content: session.activities, emptyMessage: "Keine Aktivitäten erfasst"))
        lines.append(contentsOf: textSection("Pläne", content: session.plans, emptyMessage: "Keine Pläne erfasst"))
        lines.append(contentsOf: textSection("Gedanken", content: session.thoughts, emptyMessage: "Keine Gedanken erfasst"))

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

    private static func textSection(_ title: String, content: String, emptyMessage: String) -> [String] {
        ["## \(title)", content.isEmpty ? "*\(emptyMessage)*" : content, ""]
    }
}
