//
//  DraftsListView.swift
//  PokéJournal Capture
//

import SwiftUI
import SwiftData

struct DraftsListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<DraftSession> { $0.statusRaw == "draft" },
           sort: \DraftSession.updatedAt, order: .reverse)
    private var drafts: [DraftSession]

    let onSelect: (DraftSession) -> Void

    var body: some View {
        Group {
            if drafts.isEmpty {
                ContentUnavailableView(
                    "Keine Entwürfe",
                    systemImage: "doc.text",
                    description: Text("Du hast keine offenen Session-Entwürfe.")
                )
            } else {
                List {
                    ForEach(drafts) { draft in
                        draftRow(draft)
                    }
                    .onDelete(perform: deleteDrafts)
                }
            }
        }
        .navigationTitle("Entwürfe")
        .toolbar {
            if !drafts.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func draftRow(_ draft: DraftSession) -> some View {
        Button {
            onSelect(draft)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(draft.game?.name ?? "Kein Spiel")
                        .fontWeight(.medium)
                    Spacer()
                    Text(draft.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    if !draft.activities.isEmpty {
                        Label("Aktivitäten", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    if !draft.plans.isEmpty {
                        Label("Pläne", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    if !draft.team.isEmpty {
                        Label("\(draft.team.count) Pokémon", systemImage: "person.3.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .labelStyle(.iconOnly)

                Text("Aktualisiert: \(draft.updatedAt, style: .relative)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func deleteDrafts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(drafts[index])
        }
        try? modelContext.save()
    }
}
