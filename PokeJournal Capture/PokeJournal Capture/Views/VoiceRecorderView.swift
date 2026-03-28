//
//  VoiceRecorderView.swift
//  PokéJournal Capture
//

import SwiftUI
import Speech
import AVFoundation
import Combine

@MainActor
struct VoiceRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var session: DraftSession

    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var selectedTarget: TranscriptionTarget = .activities
    @State private var showingPermissionAlert = false
    @State private var permissionMessage = ""

    @StateObject private var speechRecognizer = SpeechRecognizer()

    enum TranscriptionTarget: String, CaseIterable {
        case activities = "Aktivitäten"
        case plans = "Pläne"
        case thoughts = "Gedanken"

        var icon: String {
            switch self {
            case .activities: return "figure.run"
            case .plans: return "list.bullet.clipboard"
            case .thoughts: return "brain.head.profile"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Target Section Picker
                VStack(spacing: 8) {
                    Text("Ziel-Bereich")
                        .font(.headline)
                    Picker("Ziel", selection: $selectedTarget) {
                        ForEach(TranscriptionTarget.allCases, id: \.self) { target in
                            Label(target.rawValue, systemImage: target.icon)
                                .tag(target)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                // Transcription Display
                VStack(spacing: 8) {
                    Text("Transkription")
                        .font(.headline)
                    ScrollView {
                        Text(transcribedText.isEmpty ? "Sprich, um Text zu erzeugen..." : transcribedText)
                            .foregroundStyle(transcribedText.isEmpty ? .tertiary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: 150)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()

                // Record Button
                Button {
                    toggleRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? .red : .blue)
                            .frame(width: 100, height: 100)
                            .shadow(color: isRecording ? .red.opacity(0.5) : .blue.opacity(0.5), radius: 10)

                        if isRecording {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white)
                                .frame(width: 30, height: 30)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .sensoryFeedback(.impact, trigger: isRecording)

                Text(isRecording ? "Tippe zum Stoppen" : "Tippe zum Aufnehmen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                // Add Button
                if !transcribedText.isEmpty {
                    Button {
                        addTranscription()
                    } label: {
                        Label("Zu \(selectedTarget.rawValue) hinzufügen", systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Sprachnotiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        if isRecording {
                            speechRecognizer.stopTranscribing()
                        }
                        dismiss()
                    }
                }
            }
            .alert("Berechtigung erforderlich", isPresented: $showingPermissionAlert) {
                Button("OK") { }
                Button("Einstellungen öffnen") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(permissionMessage)
            }
            .onReceive(speechRecognizer.$transcript) { text in
                transcribedText = text
            }
        }
    }

    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopTranscribing()
            isRecording = false
        } else {
            Task {
                do {
                    try await speechRecognizer.startTranscribing()
                    isRecording = true
                } catch SpeechRecognizer.RecognizerError.notAuthorizedToRecognize {
                    permissionMessage = "Bitte erlaube Spracherkennung in den Einstellungen."
                    showingPermissionAlert = true
                } catch SpeechRecognizer.RecognizerError.notPermittedToRecord {
                    permissionMessage = "Bitte erlaube Mikrofonzugriff in den Einstellungen."
                    showingPermissionAlert = true
                } catch SpeechRecognizer.RecognizerError.recognizerUnavailable {
                    permissionMessage = "Spracherkennung ist auf diesem Gerät nicht verfügbar. Bitte stelle sicher, dass die deutsche Sprache heruntergeladen ist."
                    showingPermissionAlert = true
                } catch {
                    permissionMessage = "Ein Fehler ist aufgetreten: \(error.localizedDescription)"
                    showingPermissionAlert = true
                }
            }
        }
    }

    private func addTranscription() {
        guard !transcribedText.isEmpty else { return }

        let textToAdd = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch selectedTarget {
        case .activities:
            if session.activities.isEmpty {
                session.activities = textToAdd
            } else {
                session.activities += "\n\n" + textToAdd
            }
        case .plans:
            if session.plans.isEmpty {
                session.plans = textToAdd
            } else {
                session.plans += "\n\n" + textToAdd
            }
        case .thoughts:
            if session.thoughts.isEmpty {
                session.thoughts = textToAdd
            } else {
                session.thoughts += "\n\n" + textToAdd
            }
        }

        session.voiceNotes.append(textToAdd)
        session.markUpdated()
        transcribedText = ""
    }
}

// MARK: - Speech Recognizer

@MainActor
class SpeechRecognizer: ObservableObject {
    enum RecognizerError: Error {
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerUnavailable
    }

    @Published var transcript: String = ""

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    private var confirmedTranscription: String = ""
    private var lastResultLength: Int = 0

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    }

    func startTranscribing() async throws {
        // Reset transcription state
        transcript = ""
        confirmedTranscription = ""
        lastResultLength = 0

        // Request authorization
        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard authStatus == .authorized else {
            throw RecognizerError.notAuthorizedToRecognize
        }

        // Request microphone permission
        let audioSession = AVAudioSession.sharedInstance()
        let permissionGranted = await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard permissionGranted else {
            throw RecognizerError.notPermittedToRecord
        }

        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw RecognizerError.recognizerUnavailable
        }

        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.handleRecognitionResult(result: result, error: error)
            }
        }
    }

    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            let newText = result.bestTranscription.formattedString
            let newLength = newText.count

            // iOS resets recognition after pauses, causing shorter results.
            // Detect this and preserve the existing transcription.
            if newLength < lastResultLength && lastResultLength > 0 {
                confirmCurrentTranscription()
            }

            lastResultLength = newLength

            if confirmedTranscription.isEmpty {
                transcript = newText
            } else if !newText.isEmpty {
                transcript = confirmedTranscription + " " + newText
            }

            if result.isFinal {
                confirmCurrentTranscription()
            }
        }

        if let error = error {
            let nsError = error as NSError
            let isExpectedError = nsError.domain == "kAFAssistantErrorDomain"

            if isExpectedError {
                confirmCurrentTranscription()
            } else {
                stopTranscribing()
            }
        }
    }

    private func confirmCurrentTranscription() {
        if !transcript.isEmpty {
            confirmedTranscription = transcript
        }
        lastResultLength = 0
    }

    func stopTranscribing() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()

        audioEngine = nil
        request = nil
        task = nil
    }
}
