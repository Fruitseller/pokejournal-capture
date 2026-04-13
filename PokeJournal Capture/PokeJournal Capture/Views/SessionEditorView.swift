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
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \Game.lastUsedAt, order: .reverse)
    private var games: [Game]

    // Local text buffers to decouple keystrokes from SwiftData change tracking
    @State private var activitiesText = ""
    @State private var plansText = ""
    @State private var thoughtsText = ""
    @State private var isDirty = false
    @State private var isLoading = false

    @State private var showingGamePicker = false
    @State private var showingTeamEditor = false
    @State private var showingVoiceRecorder = false
    @State private var showingExportPreview = false
    @State private var copiedToClipboard = false

    private let autosaveTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            // MARK: - Game & Date
            Section {
                Button {
                    showingGamePicker = true
                } label: {
                    LabeledContent {
                        HStack {
                            Text(session.game?.name ?? "Auswählen")
                                .foregroundStyle(session.game == nil ? .secondary : .primary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } label: {
                        Label("Spiel", systemImage: "gamecontroller.fill")
                    }
                }
                .buttonStyle(.plain)

                DatePicker(
                    selection: $session.date,
                    displayedComponents: .date
                ) {
                    Label("Datum", systemImage: "calendar")
                }
            }

            // MARK: - Voice Recording
            Section {
                Button {
                    showingVoiceRecorder = true
                } label: {
                    Label {
                        HStack {
                            Text("Sprachnotiz aufnehmen")
                            Spacer()
                            if !session.voiceNotes.isEmpty {
                                Text("\(session.voiceNotes.count)")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.accent, in: Capsule())
                            }
                        }
                    } icon: {
                        Image(systemName: "mic.fill")
                    }
                }
                .buttonStyle(.plain)
            }

            // MARK: - Activities
            Section {
                TextEditor(text: $activitiesText)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if activitiesText.isEmpty {
                            Text("Was hast du gemacht?")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: activitiesText) { if !isLoading { isDirty = true } }
            } header: {
                Label("Aktivitäten", systemImage: "figure.run")
            }

            // MARK: - Plans
            Section {
                TextEditor(text: $plansText)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if plansText.isEmpty {
                            Text("Was planst du als nächstes?")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: plansText) { if !isLoading { isDirty = true } }
            } header: {
                Label("Pläne", systemImage: "list.bullet.clipboard")
            }

            // MARK: - Thoughts
            Section {
                TextEditor(text: $thoughtsText)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if thoughtsText.isEmpty {
                            Text("Sonstige Gedanken...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: thoughtsText) { if !isLoading { isDirty = true } }
            } header: {
                Label("Gedanken", systemImage: "brain.head.profile")
            }

            // MARK: - Team
            Section {
                if session.team.isEmpty {
                    Button {
                        showingTeamEditor = true
                    } label: {
                        Label("Team hinzufügen", systemImage: "plus.circle")
                    }
                } else {
                    TeamPreviewGrid(team: session.team.sorted { $0.slotIndex < $1.slotIndex })

                    Button {
                        showingTeamEditor = true
                    } label: {
                        Label("Team bearbeiten", systemImage: "pencil")
                    }
                }
            } header: {
                Label("Team", systemImage: "person.3.fill")
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                exportMenu
            }
        }
        .sheet(isPresented: $showingGamePicker) {
            GamePickerView(selectedGame: $session.game)
        }
        .sheet(isPresented: $showingTeamEditor) {
            TeamEditorView(session: session)
        }
        .sheet(isPresented: $showingVoiceRecorder, onDismiss: {
            loadFromSession()
        }) {
            VoiceRecorderView(session: $session)
        }
        .onChange(of: showingVoiceRecorder) {
            if showingVoiceRecorder { flushIfDirty() }
        }
        .sheet(isPresented: $showingExportPreview) {
            ExportPreviewView(session: session, onCopy: copyToClipboard)
        }
        .onAppear {
            loadFromSession()
        }
        .onDisappear {
            flushIfDirty()
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                flushIfDirty()
            }
        }
        .onReceive(autosaveTimer) { _ in
            flushIfDirty()
        }
        .sensoryFeedback(.success, trigger: copiedToClipboard)
    }

    // MARK: - Export

    private var exportMenu: some View {
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

    private func loadFromSession() {
        isLoading = true
        activitiesText = session.activities
        plansText = session.plans
        thoughtsText = session.thoughts
        isDirty = false
        DispatchQueue.main.async { isLoading = false }
    }

    private func syncToSession() {
        session.activities = activitiesText
        session.plans = plansText
        session.thoughts = thoughtsText
    }

    private func flushIfDirty() {
        guard isDirty else { return }
        syncToSession()
        session.markUpdated()
        try? modelContext.save()
        isDirty = false
    }

    private func copyToClipboard() {
        syncToSession()
        let markdown = ExportService.generateMarkdown(for: session)
        UIPasteboard.general.string = markdown
        copiedToClipboard.toggle()
        session.markExported()
        try? modelContext.save()
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
            }
        }
    }
}
