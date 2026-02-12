//
//  SessionEditorView.swift
//  PokéJournal Capture
//

import SwiftUI
import SwiftData
import Combine

struct SessionEditorView: View {
    @Binding var session: DraftSession
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Game.lastUsedAt, order: .reverse)
    private var games: [Game]

    @State private var showingGamePicker = false
    @State private var showingTeamEditor = false
    @State private var showingVoiceRecorder = false
    @State private var showingExportPreview = false
    @State private var copiedToClipboard = false

    private let autosaveTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection

                Divider()

                voiceRecordingSection

                Divider()

                textFieldsSection

                Divider()

                teamSection

                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                exportButton
            }
        }
        .sheet(isPresented: $showingGamePicker) {
            GamePickerView(selectedGame: $session.game)
        }
        .sheet(isPresented: $showingTeamEditor) {
            TeamEditorView(session: session)
        }
        .sheet(isPresented: $showingVoiceRecorder) {
            VoiceRecorderView(session: $session)
        }
        .sheet(isPresented: $showingExportPreview) {
            ExportPreviewView(session: session, onCopy: copyToClipboard)
        }
        .onReceive(autosaveTimer) { _ in
            session.markUpdated()
            try? modelContext.save()
        }
        .sensoryFeedback(.success, trigger: copiedToClipboard)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Game Selection
            Button {
                showingGamePicker = true
            } label: {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                    Text(session.game?.name ?? "Spiel wählen")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Date Display
            HStack {
                Image(systemName: "calendar")
                Text(session.date, style: .date)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        }
    }

    // MARK: - Voice Recording Section

    private var voiceRecordingSection: some View {
        VStack(spacing: 12) {
            Button {
                showingVoiceRecorder = true
            } label: {
                HStack {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                    Text("Sprachnotiz aufnehmen")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            if !session.voiceNotes.isEmpty {
                Text("\(session.voiceNotes.count) Sprachnotiz(en) aufgenommen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Text Fields Section

    private var textFieldsSection: some View {
        VStack(spacing: 16) {
            ExpandableTextField(
                title: "Aktivitäten",
                icon: "figure.run",
                text: $session.activities,
                placeholder: "Was hast du gemacht?"
            )

            ExpandableTextField(
                title: "Pläne",
                icon: "list.bullet.clipboard",
                text: $session.plans,
                placeholder: "Was planst du als nächstes?"
            )

            ExpandableTextField(
                title: "Gedanken",
                icon: "brain.head.profile",
                text: $session.thoughts,
                placeholder: "Sonstige Gedanken..."
            )
        }
    }

    // MARK: - Team Section

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                Text("Team")
                    .font(.headline)
                Spacer()
                Button {
                    showingTeamEditor = true
                } label: {
                    Text("Bearbeiten")
                        .font(.subheadline)
                }
            }

            if session.team.isEmpty {
                Button {
                    showingTeamEditor = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Team hinzufügen")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                TeamPreviewGrid(team: session.team.sorted { $0.slotIndex < $1.slotIndex })
            }
        }
    }

    // MARK: - Export

    private var exportButton: some View {
        Menu {
            Button {
                copyToClipboard()
            } label: {
                Label("In Zwischenablage kopieren", systemImage: "doc.on.clipboard")
            }

            Button {
                showingExportPreview = true
            } label: {
                Label("Vorschau anzeigen", systemImage: "eye")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
        }
    }

    private func copyToClipboard() {
        let markdown = ExportService.generateMarkdown(for: session)
        UIPasteboard.general.string = markdown
        copiedToClipboard.toggle()
        session.markExported()
        try? modelContext.save()
    }
}

// MARK: - Expandable Text Field

struct ExpandableTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let placeholder: String

    @State private var isExpanded = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                    if isExpanded {
                        isFocused = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                    Text(title)
                        .fontWeight(.medium)
                    Spacer()
                    if !text.isEmpty {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundStyle(.tertiary)
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(16)
                        }
                    }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Team Preview Grid

struct TeamPreviewGrid: View {
    let team: [TeamMember]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(team, id: \.pokemonName) { member in
                VStack(spacing: 4) {
                    Text(member.pokemonName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text("Lv. \(member.level)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
