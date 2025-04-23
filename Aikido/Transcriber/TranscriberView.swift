//
//  TranscriberView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/30/25.
//

import SwiftUI

struct TranscriberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var url: URL?

    @State private var transcription: String = "Transcribing..."
    @State private var summary: String?
    @State private var selectedTab: RecordingTab = .transcription

    var body: some View {
        NavigationStack {
            contentView
                .toolbar {
                    TranscriberToolbar(cancelAction: deleteRecording,
                                       saveAction: saveRecording)
                }
                .onAppear {
                    transcribeAndSummarize()
                }
        }
    }
    
    var contentView: some View {
        VStack {
            if let url {
                Text(url.lastPathComponent)
            }

//            ScrollView {
//                Text(transcription)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            .padding()
//            .background(Color.gray.opacity(0.1))
//            .cornerRadius(10)
            VStack {
                Picker("", selection: $selectedTab) {
                    ForEach(RecordingTab.allCases) { tab in
                        Text(tab.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                
                ScrollView {
                    switch selectedTab {
                    case .transcription:
                        Text(transcription)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .summary:
                        Text(summary ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
    }
    
    private func transcribeAndSummarize() {
        guard let url else {
            return
        }

        Task {
            do {
                if let text = try await WhisperManager.shared.transcribeAudio(url: url) {
                    transcription = text
                    summary = await WhisperManager.shared.summarize(text: text)
                } else {
                    transcription = ""
                    summary = nil
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func deleteRecording() {
        if let url {
            WhisperManager.shared.deleteRecording(url: url)
        }
        dismiss()
    }

    private func saveRecording() {
        if let url {
            Task {
                do {
                    try await WhisperManager.shared.saveRecording(url: url,
                                                                  transcription: transcription,
                                                                  summary: summary)
                } catch {
                    print("\(#function) Error: \(error)")
                }
            }
        }
        dismiss()
    }
}

#Preview {
    TranscriberView()
}

struct TranscriberToolbar: ToolbarContent {
    var cancelAction: () -> Void
    var saveAction: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: {
                cancelAction()
            }, label: {
                Text("Cancel")
            })
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                saveAction()
            }, label: {
                Text("Save")
            })
        }
    }
}
