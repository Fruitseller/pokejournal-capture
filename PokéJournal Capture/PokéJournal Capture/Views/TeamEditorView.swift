//
//  TeamEditorView.swift
//  PokéJournal Capture
//

import SwiftUI
import SwiftData

struct TeamEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: DraftSession

    @Query(filter: #Predicate<DraftSession> { $0.statusRaw == "exported" },
           sort: \DraftSession.updatedAt, order: .reverse)
    private var exportedSessions: [DraftSession]

    @State private var selectedSlot: Int?
    @State private var showingPokemonSearch = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let lastSession = lastSessionWithTeam, session.team.isEmpty {
                    copyFromLastSessionButton(lastSession)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        teamSlot(at: index)
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Team bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPokemonSearch) {
                if let slot = selectedSlot {
                    PokemonSearchView { pokemon, level, variant in
                        addOrUpdateTeamMember(
                            at: slot,
                            pokemon: pokemon,
                            level: level,
                            variant: variant
                        )
                    }
                }
            }
        }
    }

    private var lastSessionWithTeam: DraftSession? {
        exportedSessions.first { session in
            !session.team.isEmpty && session.game?.id == self.session.game?.id
        } ?? exportedSessions.first { !$0.team.isEmpty }
    }

    private func copyFromLastSessionButton(_ lastSession: DraftSession) -> some View {
        Button {
            copyTeam(from: lastSession)
        } label: {
            HStack {
                Image(systemName: "doc.on.doc")
                VStack(alignment: .leading) {
                    Text("Team von letzter Session kopieren")
                        .fontWeight(.medium)
                    Text("\(lastSession.team.count) Pokémon • \(lastSession.date, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private func teamSlot(at index: Int) -> some View {
        let member = session.team.first { $0.slotIndex == index }

        return Button {
            selectedSlot = index
            showingPokemonSearch = true
        } label: {
            VStack(spacing: 8) {
                if let member = member {
                    Text(member.pokemonName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text("Lv. \(member.level)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let variant = member.variant, !variant.isEmpty {
                        Text(variant)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                } else {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Leer")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if member != nil {
                Button(role: .destructive) {
                    removeTeamMember(at: index)
                } label: {
                    Label("Entfernen", systemImage: "trash")
                }
            }
        }
    }

    private func addOrUpdateTeamMember(at slot: Int, pokemon: Pokemon, level: Int, variant: String?) {
        // Remove existing member at this slot
        if let existingMember = session.team.first(where: { $0.slotIndex == slot }) {
            modelContext.delete(existingMember)
            session.team.removeAll { $0.slotIndex == slot }
        }

        let newMember = TeamMember(
            pokemonName: pokemon.nameDE,
            level: level,
            variant: variant,
            nationalDexNumber: pokemon.id,
            slotIndex: slot
        )
        session.team.append(newMember)
        session.markUpdated()
        try? modelContext.save()
    }

    private func removeTeamMember(at slot: Int) {
        if let member = session.team.first(where: { $0.slotIndex == slot }) {
            modelContext.delete(member)
            session.team.removeAll { $0.slotIndex == slot }
            session.markUpdated()
            try? modelContext.save()
        }
    }

    private func copyTeam(from otherSession: DraftSession) {
        // Clear current team
        for member in session.team {
            modelContext.delete(member)
        }
        session.team.removeAll()

        // Copy team members
        for member in otherSession.team {
            let newMember = TeamMember(
                pokemonName: member.pokemonName,
                level: member.level,
                variant: member.variant,
                nationalDexNumber: member.nationalDexNumber,
                slotIndex: member.slotIndex
            )
            session.team.append(newMember)
        }
        session.markUpdated()
        try? modelContext.save()
    }
}

// MARK: - Pokemon Search View

struct PokemonSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var pokemonStore = PokemonDataStore.shared

    @State private var searchText = ""
    @State private var selectedPokemon: Pokemon?
    @State private var level: Int = 50
    @State private var variant: String = ""

    let onSelect: (Pokemon, Int, String?) -> Void

    private var filteredPokemon: [Pokemon] {
        pokemonStore.search(query: searchText)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let pokemon = selectedPokemon {
                    levelInputView(pokemon: pokemon)
                } else {
                    pokemonListView
                }
            }
            .navigationTitle(selectedPokemon == nil ? "Pokémon suchen" : "Level eingeben")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var pokemonListView: some View {
        List(filteredPokemon) { pokemon in
            Button {
                selectedPokemon = pokemon
            } label: {
                HStack {
                    Text("#\(pokemon.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    VStack(alignment: .leading) {
                        Text(pokemon.nameDE)
                            .fontWeight(.medium)
                        Text(pokemon.nameEN)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(pokemon.types, id: \.self) { type in
                            Text(type)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(typeColor(for: type).opacity(0.3), in: Capsule())
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .searchable(text: $searchText, prompt: "Name oder Nummer")
    }

    private func levelInputView(pokemon: Pokemon) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(pokemon.nameDE)
                    .font(.title)
                    .fontWeight(.bold)
                Text("#\(pokemon.id) • \(pokemon.types.joined(separator: ", "))")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("Level")
                    .font(.headline)
                HStack {
                    Button {
                        if level > 1 { level -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                    }
                    .disabled(level <= 1)

                    TextField("Level", value: $level, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(width: 80)

                    Button {
                        if level < 100 { level += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                    .disabled(level >= 100)
                }
            }

            VStack(spacing: 8) {
                Text("Variante (optional)")
                    .font(.headline)
                TextField("z.B. Alola, Galar, Hisui", text: $variant)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 250)
            }

            Spacer()

            Button {
                let finalVariant = variant.isEmpty ? nil : variant
                onSelect(pokemon, max(1, min(100, level)), finalVariant)
                dismiss()
            } label: {
                Text("Hinzufügen")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding()
        }
        .padding()
    }

    private func typeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "normal": return .gray
        case "feuer": return .orange
        case "wasser": return .blue
        case "elektro": return .yellow
        case "pflanze": return .green
        case "eis": return .cyan
        case "kampf": return .red
        case "gift": return .purple
        case "boden": return .brown
        case "flug": return .indigo
        case "psycho": return .pink
        case "käfer": return .green.opacity(0.7)
        case "gestein": return .brown.opacity(0.7)
        case "geist": return .purple.opacity(0.7)
        case "drache": return .indigo
        case "unlicht": return .black
        case "stahl": return .gray.opacity(0.7)
        case "fee": return .pink.opacity(0.7)
        default: return .gray
        }
    }
}
