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
    @State private var selectedTab: AppTab = .session

    enum AppTab: Hashable {
        case session
        case drafts
        case games
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Session", systemImage: "gamecontroller.fill", value: AppTab.session) {
                NavigationStack {
                    if let session = currentSession {
                        SessionEditorView(session: Binding(
                            get: { session },
                            set: { currentSession = $0 }
                        ))
                        .id(session.id)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    createNewSession()
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                    }
                }
            }

            Tab("Entwürfe", systemImage: "doc.text", value: AppTab.drafts) {
                NavigationStack {
                    DraftsListView(onSelect: { session in
                        currentSession = session
                        selectedTab = .session
                    })
                }
            }
            .badge(drafts.count)

            Tab("Spiele", systemImage: "list.bullet", value: AppTab.games) {
                NavigationStack {
                    GamesManagementView()
                }
            }
        }
        .onAppear {
            initializeSession()
        }
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
}
