//
//  ContentView.swift
//  PokéJournal Capture
//
//  Created by Piotr Großmann on 31.01.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<DraftSession> { $0.statusRaw == "draft" },
           sort: \DraftSession.updatedAt, order: .reverse)
    private var drafts: [DraftSession]

    @State private var currentSession: DraftSession?
    @State private var showingDrafts = false
    @State private var showingGames = false

    var body: some View {
        NavigationStack {
            SessionEditorView(session: currentSessionBinding)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                showingDrafts = true
                            } label: {
                                Label("Entwürfe (\(drafts.count))", systemImage: "doc.text")
                            }

                            Button {
                                showingGames = true
                            } label: {
                                Label("Spiele verwalten", systemImage: "gamecontroller")
                            }

                            Divider()

                            Button {
                                createNewSession()
                            } label: {
                                Label("Neue Session", systemImage: "plus")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                        }
                    }
                }
                .sheet(isPresented: $showingDrafts) {
                    DraftsListView(onSelect: { session in
                        currentSession = session
                        showingDrafts = false
                    })
                }
                .sheet(isPresented: $showingGames) {
                    GamesManagementView()
                }
        }
        .onAppear {
            initializeSession()
        }
    }

    private var currentSessionBinding: Binding<DraftSession> {
        Binding(
            get: { currentSession ?? createAndReturnNewSession() },
            set: { currentSession = $0 }
        )
    }

    private func initializeSession() {
        if let latestDraft = drafts.first {
            currentSession = latestDraft
        } else {
            createNewSession()
        }
    }

    private func createNewSession() {
        let session = DraftSession()
        modelContext.insert(session)
        currentSession = session
    }

    private func createAndReturnNewSession() -> DraftSession {
        let session = DraftSession()
        modelContext.insert(session)
        currentSession = session
        return session
    }
}

// Note: SwiftData Previews are currently broken in Xcode.
// Use Simulator (Cmd+R) to test the app.
