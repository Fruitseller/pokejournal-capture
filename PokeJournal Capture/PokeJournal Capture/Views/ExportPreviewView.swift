//
//  ExportPreviewView.swift
//  PokéJournal Capture
//

import SwiftUI

struct ExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let session: DraftSession
    let onCopy: () -> Void

    @State private var copied = false

    private var markdownContent: String {
        ExportService.generateMarkdown(for: session)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(markdownContent)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Export Vorschau")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onCopy()
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    } label: {
                        if copied {
                            Label("Kopiert!", systemImage: "checkmark")
                        } else {
                            Label("Kopieren", systemImage: "doc.on.clipboard")
                        }
                    }
                }
            }
            .sensoryFeedback(.success, trigger: copied)
        }
    }
}
